import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class CaregiverScreen extends StatefulWidget {
  final String circleId;
  final String caregiverId;

  const CaregiverScreen({
    super.key,
    required this.circleId,
    required this.caregiverId,
  });

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Caregiver Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ACTIVE ALERTS STREAM
            StreamBuilder<List<AlertModel>>(
              stream: _firestoreService.streamAlerts(widget.circleId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final activeAlerts = snapshot.data!
                    .where((a) => a.status == 'ACTIVE')
                    .toList();

                if (activeAlerts.isEmpty) {
                  return Card(
                    color: Colors.green.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.green, size: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All Clear: No active emergency alerts.',
                              style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: activeAlerts.map((alert) {
                    final isSos = alert.type == 'SOS';
                    return Card(
                      color: isSos ? Colors.red.shade700 : Colors.amber.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isSos ? Icons.warning_rounded : Icons.alarm_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isSos ? '🚨 CRITICAL EMERGENCY SOS' : '⚠️ MISSED CHECK-IN ALERT',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              alert.message,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            if (alert.latitude != null && alert.longitude != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '📍 GPS: ${alert.latitude!.toStringAsFixed(5)}, ${alert.longitude!.toStringAsFixed(5)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: isSos ? Colors.red.shade800 : Colors.amber.shade900,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  await _firestoreService.acknowledgeAlert(
                                    alertId: alert.id,
                                    caregiverId: widget.caregiverId,
                                    notes: 'Acknowledged by caregiver in mobile app',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Alert status updated to ACKNOWLEDGED.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text(
                                  'ACKNOWLEDGE ALERT',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // SENIOR MORNING STATUS
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Check-in Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    StreamBuilder<CheckinModel?>(
                      stream: _firestoreService.streamTodayCheckin(widget.circleId),
                      builder: (context, snapshot) {
                        final checkedIn = snapshot.data?.morningCheckedIn == true;
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: checkedIn ? Colors.green.shade100 : Colors.orange.shade100,
                              child: Icon(
                                checkedIn ? Icons.check : Icons.hourglass_top_rounded,
                                color: checkedIn ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    checkedIn ? 'Checked In' : 'Pending 10:00 AM Check-in',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: checkedIn ? Colors.green.shade800 : Colors.orange.shade900,
                                    ),
                                  ),
                                  Text(
                                    checkedIn
                                        ? 'Checked in at ${DateFormat.jm().format(snapshot.data?.timestamp ?? DateTime.now())}'
                                        : 'Automated alert triggers if not checked in by 10:00 AM local time.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // MEDICATION ADHERENCE TRACKER
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Medication Adherence Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    StreamBuilder<List<MedicationModel>>(
                      stream: _firestoreService.streamMedications(widget.circleId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final meds = snapshot.data!;
                        if (meds.isEmpty) {
                          return const Text('No active medications configured.');
                        }

                        final takenCount = meds.where((m) => m.takenToday).length;
                        final percent = meds.isNotEmpty ? takenCount / meds.length : 0.0;

                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: percent,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              color: percent == 1.0 ? Colors.green : Colors.teal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$takenCount of ${meds.length} taken', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${(percent * 100).toInt()}% completed', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const Divider(height: 24),
                            ...meds.map((m) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    m.takenToday ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: m.takenToday ? Colors.green : Colors.grey,
                                  ),
                                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(m.dosage),
                                  trailing: Text(
                                    m.takenToday ? 'Taken' : 'Pending',
                                    style: TextStyle(
                                      color: m.takenToday ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )),
                          ],
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
