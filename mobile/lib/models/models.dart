import 'package:cloud_firestore/cloud_firestore.dart';

class CareCircleModel {
  final String id;
  final String name;
  final String primarySeniorId;
  final List<String> caregiverIds;
  final List<Map<String, dynamic>> emergencyContacts;
  final String timezone;
  final bool isActive;

  CareCircleModel({
    required this.id,
    required this.name,
    required this.primarySeniorId,
    required this.caregiverIds,
    required this.emergencyContacts,
    required this.timezone,
    this.isActive = true,
  });

  factory CareCircleModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CareCircleModel(
      id: doc.id,
      name: data['name'] ?? 'Family Circle',
      primarySeniorId: data['primarySeniorId'] ?? '',
      caregiverIds: List<String>.from(data['caregiverIds'] ?? []),
      emergencyContacts: List<Map<String, dynamic>>.from(data['emergencyContacts'] ?? []),
      timezone: data['timezone'] ?? 'UTC',
      isActive: data['isActive'] ?? true,
    );
  }
}

class AlertModel {
  final String id;
  final String circleId;
  final String type; // 'SOS', 'NO_CHECKIN', 'MISSED_MEDICATION'
  final String status; // 'ACTIVE', 'ACKNOWLEDGED', 'RESOLVED'
  final String message;
  final DateTime? triggeredAt;
  final double? latitude;
  final double? longitude;
  final bool escalated;

  AlertModel({
    required this.id,
    required this.circleId,
    required this.type,
    required this.status,
    required this.message,
    this.triggeredAt,
    this.latitude,
    this.longitude,
    this.escalated = false,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final Timestamp? timestamp = data['triggeredAt'] is Timestamp ? data['triggeredAt'] : null;

    double? lat;
    double? lng;
    if (data['location'] is Map) {
      lat = (data['location']['latitude'] as num?)?.toDouble();
      lng = (data['location']['longitude'] as num?)?.toDouble();
    } else {
      lat = (data['latitude'] as num?)?.toDouble();
      lng = (data['longitude'] as num?)?.toDouble();
    }

    return AlertModel(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      type: data['type'] ?? 'UNKNOWN',
      status: data['status'] ?? 'ACTIVE',
      message: data['message'] ?? '',
      triggeredAt: timestamp?.toDate(),
      latitude: lat,
      longitude: lng,
      escalated: data['escalated'] ?? false,
    );
  }
}

class MedicationModel {
  final String id;
  final String circleId;
  final String name;
  final String dosage;
  final bool takenToday;
  final DateTime? lastConfirmedAt;

  MedicationModel({
    required this.id,
    required this.circleId,
    required this.name,
    required this.dosage,
    required this.takenToday,
    this.lastConfirmedAt,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final Timestamp? confirmedTs = data['lastConfirmedAt'] is Timestamp ? data['lastConfirmedAt'] : null;

    return MedicationModel(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      name: data['name'] ?? 'Medication',
      dosage: data['dosage'] ?? '',
      takenToday: data['takenToday'] ?? false,
      lastConfirmedAt: confirmedTs?.toDate(),
    );
  }
}

class CheckinModel {
  final String id;
  final String circleId;
  final String date;
  final bool morningCheckedIn;
  final DateTime? timestamp;

  CheckinModel({
    required this.id,
    required this.circleId,
    required this.date,
    required this.morningCheckedIn,
    this.timestamp,
  });

  factory CheckinModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final Timestamp? ts = data['timestamp'] is Timestamp ? data['timestamp'] : null;

    return CheckinModel(
      id: doc.id,
      circleId: data['circleId'] ?? '',
      date: data['date'] ?? '',
      morningCheckedIn: data['morningCheckedIn'] ?? false,
      timestamp: ts?.toDate(),
    );
  }
}
