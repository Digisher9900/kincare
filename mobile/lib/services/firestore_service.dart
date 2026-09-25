import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Streams active alerts for a care circle
  Stream<List<AlertModel>> streamAlerts(String circleId) {
    return _db
        .collection('alerts')
        .where('circleId', isEqualTo: circleId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList());
  }

  // Streams daily medications for a care circle
  Stream<List<MedicationModel>> streamMedications(String circleId) {
    return _db
        .collection('medications')
        .where('circleId', isEqualTo: circleId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicationModel.fromFirestore(doc))
            .toList());
  }

  // Streams today's checkin for a care circle
  Stream<CheckinModel?> streamTodayCheckin(String circleId) {
    final String todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _db
        .collection('checkins')
        .where('circleId', isEqualTo: circleId)
        .where('date', isEqualTo: todayDateStr)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CheckinModel.fromFirestore(snapshot.docs.first);
    });
  }

  // Trigger Senior SOS (Conforms to firestore.rules and activates onSosTriggered Cloud Function)
  Future<String> triggerEmergencySos({
    required String circleId,
    double? latitude,
    double? longitude,
  }) async {
    final alertRef = await _db.collection('alerts').add({
      'circleId': circleId,
      'type': 'SOS',
      'status': 'ACTIVE',
      'message': '🚨 Emergency SOS triggered by Senior!',
      'triggeredAt': FieldValue.serverTimestamp(),
      'escalated': false,
      if (latitude != null && longitude != null)
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
    });
    return alertRef.id;
  }

  // Submit Morning Check-in (Validates date matches current date or earlier)
  Future<void> submitMorningCheckin({
    required String circleId,
  }) async {
    final String todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _db.collection('checkins').add({
      'circleId': circleId,
      'date': todayDateStr,
      'morningCheckedIn': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Senior updates medication adherence (Only changes takenToday and lastConfirmedAt)
  Future<void> confirmMedicationTaken(String medId) async {
    await _db.collection('medications').doc(medId).update({
      'takenToday': true,
      'lastConfirmedAt': FieldValue.serverTimestamp(),
    });
  }

  // Caregiver acknowledges an active alert (Only changes status to ACKNOWLEDGED & metadata)
  Future<void> acknowledgeAlert({
    required String alertId,
    required String caregiverId,
    String? notes,
  }) async {
    await _db.collection('alerts').doc(alertId).update({
      'status': 'ACKNOWLEDGED',
      'acknowledgedAt': FieldValue.serverTimestamp(),
      'acknowledgedBy': caregiverId,
      if (notes != null && notes.isNotEmpty) 'resolutionNotes': notes,
    });
  }

  // Helper to seed a test care circle if needed
  Future<void> seedDemoCircle({
    required String circleId,
    required String seniorId,
    required String caregiverId,
  }) async {
    final circleRef = _db.collection('care_circles').doc(circleId);
    await circleRef.set({
      'name': 'Smith Family Circle',
      'primarySeniorId': seniorId,
      'caregiverIds': [caregiverId],
      'timezone': 'America/New_York',
      'isActive': true,
      'emergencyContacts': [
        {
          'name': 'Primary Caregiver (Jane)',
          'phone': '+15551234567',
          'relationship': 'Daughter',
          'userId': caregiverId,
        },
        {
          'name': 'Backup Contact (Robert)',
          'phone': '+15559876543',
          'relationship': 'Son',
        }
      ],
    }, SetOptions(merge: true));

    // Seed sample medication
    await _db.collection('medications').doc('med_morning_bp').set({
      'circleId': circleId,
      'name': 'Lisinopril 10mg',
      'dosage': '1 tablet with water',
      'takenToday': false,
      'isActive': true,
    }, SetOptions(merge: true));

    await _db.collection('medications').doc('med_vitamin_d').set({
      'circleId': circleId,
      'name': 'Vitamin D3 2000 IU',
      'dosage': '1 capsule with breakfast',
      'takenToday': false,
      'isActive': true,
    }, SetOptions(merge: true));
  }
}
