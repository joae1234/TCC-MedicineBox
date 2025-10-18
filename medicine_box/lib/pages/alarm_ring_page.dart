import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicine_box/models/medication_alarm_details.dart';
import 'package:medicine_box/pages/medication_list_page.dart';

class AlarmRingPage extends StatefulWidget {
  final List<MedicationAlarmDetails> alarm;
  const AlarmRingPage({super.key, required this.alarm});

  @override
  State<AlarmRingPage> createState() => _AlarmRingPageState();
}

class _AlarmRingPageState extends State<AlarmRingPage> {
  bool _closing = false;

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedicationListPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meds = widget.alarm;

    String dosageText(dynamic d) {
      if (d == null) return '';
      if (d is num) return '$d comp.';
      final s = d.toString().trim();
      return s.isEmpty ? '' : s;
    }

    final descriptionLines =
        meds
            .map((m) => '• ${m.name} — ${dosageText(m.dosage)}')
            .where((s) => s.trim().isNotEmpty)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0EA5E9),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.alarm,
                        size: 140,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                Text(
                  'HORA DA MEDICAÇÃO',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:
                            (descriptionLines.isEmpty ? [''] : descriptionLines)
                                .map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      line,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            height: 1.3,
                                            fontSize: 20,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
