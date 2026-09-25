import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class SeniorScreen extends StatefulWidget {
  final String circleId;
  final String seniorId;

  const SeniorScreen({
    super.key,
    required this.circleId,
    required this.seniorId,
  });

  @override
  State<SeniorScreen> createState() => _SeniorScreenState();
}

class _SeniorScreenState extends State<SeniorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSosTriggering = false;

  Future<void> _handleSosPress() async {
    // Show confirmation dialog with 3-second safety abort timer
    int countdown = 3;
    Timer? timer;
    bool aborted = false;

    final shouldTrigger = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 1) {
                setDialogState(() => countdown--);
              } else {
                t.cancel();
                if (!aborted && Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop(true);
                }
              }
            });

            return AlertDialog(
              backgroundColor: Colors.red.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 12),
                  Text('EMERGENCY SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Alerting your family and emergency contacts in:',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$countdown',
                    style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'GPS location will be broadcasted.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    aborted = true;
                    timer?.cancel();
                    Navigator.of(dialogContext).pop(false);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('CANCEL (False Alarm)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    timer?.cancel();
    if (shouldTrigger != true) return;

    setState(() => _isSosTriggering = true);

    try {
      double? lat;
      double? lng;

      // Attempt to retrieve current GPS location
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 4),
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {
        // Fallback gracefully without location if GPS disabled
      }

      await _firestoreService.triggerEmergencySos(
        circleId: widget.circleId,
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              '🚨 SOS Alert broadcasted! Help is on the way.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering SOS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSosTriggering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('KinCare - Senior Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EMERGENCY SOS BUTTON
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSosTriggering ? null : _handleSosPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 42),
                    const SizedBox(width: 14),
                    Text(
                      _isSosTriggering ? 'SENDING ALERT...' : 'EMERGENCY SOS',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // MORNING CHECK-IN CARD
            StreamBuilder<CheckinModel?>(
              stream: _firestoreService.streamTodayCheckin(widget.circleId),
              builder: (context, snapshot) {
                final hasCheckedIn = snapshot.data?.morningCheckedIn == true;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: hasCheckedIn ? Colors.green.shade50 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasCheckedIn ? Icons.check_circle_rounded : Icons.wb_sunny_rounded,
                              color: hasCheckedIn ? Colors.green : Colors.amber.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Morning Check-In',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasCheckedIn
                              ? 'You have checked in for today. Have a peaceful day!'
                              : 'Please check in before 10:00 AM to let your caregivers know you are safe.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 16),
                        if (!hasCheckedIn)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                await _firestoreService.submitMorningCheckin(circleId: widget.circleId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Morning check-in confirmed!')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.thumb_up_rounded, size: 26),
                              label: const Text("I'M OK TODAY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // MEDICATIONS ADHERENCE CHECKLIST
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medication_rounded, color: Colors.indigo, size: 30),
                        SizedBox(width: 12),
                        Text('Today\'s Medications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<List<MedicationModel>>(
                      stream: _firestoreService.streamMedications(widget.circleId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                        }
                        final meds = snapshot.data!;
                        if (meds.isEmpty) {
                          return const Text('No medications scheduled for today.', style: TextStyle(fontSize: 16));
                        }

                        return Column(
                          children: meds.map((med) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: med.takenToday ? Colors.grey.shade100 : Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: med.takenToday ? Colors.grey.shade300 : Colors.indigo.shade200,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  med.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: med.takenToday ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Text(med.dosage, style: const TextStyle(fontSize: 15)),
                                trailing: med.takenToday
                                    ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => _firestoreService.confirmMedicationTaken(med.id),
                                        child: const Text('Take'),
                                      ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
