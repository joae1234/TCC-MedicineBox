import 'package:flutter/material.dart';
import '../models/medication_history.dart';

class MedicationHistoryPage extends StatelessWidget {
  final List<MedicationHistory> history;
  final Map<String, String> medNames;

  const MedicationHistoryPage({
    super.key,
    required this.history,
    required this.medNames,
  });

  // ===== Helpers simples, sem generics =====

  dynamic _read(dynamic o, String prop) {
    try {
      // Tenta acessar como propriedade conhecida
      switch (prop) {
        case 'scheduled_at':
          return (o as dynamic).scheduled_at;
        case 'scheduledAt':
          return (o as dynamic).scheduledAt;
        case 'last_status_update':
          return (o as dynamic).last_status_update;
        case 'lastStatusUpdate':
          return (o as dynamic).lastStatusUpdate;
        case 'status':
          return (o as dynamic).status;
        case 'delay_secs':
          return (o as dynamic).delay_secs;
        case 'delaySecs':
          return (o as dynamic).delaySecs;
        case 'medication_id':
          return (o as dynamic).medication_id;
        case 'medicationId':
          return (o as dynamic).medicationId;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  DateTime? _getDate(dynamic o, String snake, String camel) {
    final v = _read(o, snake) ?? _read(o, camel);
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int _getInt(dynamic o, String snake, String camel, {int def = 0}) {
    final v = _read(o, snake) ?? _read(o, camel);
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  String _getString(dynamic o, String snake, String camel, {String def = ''}) {
    final v = _read(o, snake) ?? _read(o, camel);
    return (v is String) ? v : def;
  }

  String? _getStringNullable(dynamic o, String snake, String camel) {
    final v = _read(o, snake) ?? _read(o, camel);
    return (v is String) ? v : null;
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '--';
    final l = dt.toLocal();
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(l.day)}/${p2(l.month)} ${p2(l.hour)}:${p2(l.minute)}';
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'taken':
        return Colors.green;
      case 'missed':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Medicações')),
      body:
          history.isEmpty
              ? const Center(child: Text('Nenhum histórico disponível.'))
              : ListView.builder(
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final h = history[i];

                  final medId = _getStringNullable(
                    h,
                    'medication_id',
                    'medicationId',
                  );
                  final name = medNames[medId ?? ''] ?? 'Desconhecido';

                  final scheduled = _getDate(h, 'scheduled_at', 'scheduledAt');
                  final taken = _getDate(
                    h,
                    'last_status_update',
                    'lastStatusUpdate',
                  );
                  final status = _getString(
                    h,
                    'status',
                    'status',
                    def: 'Scheduled',
                  );
                  final delaySecs = _getInt(
                    h,
                    'delay_secs',
                    'delaySecs',
                    def: 0,
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título + chip de status
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _statusColor(status),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Agendado
                          Row(
                            children: [
                              const Icon(Icons.alarm, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Agendado: ${_fmt(scheduled)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Tomado + atraso
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                taken != null
                                    ? 'Tomado: ${_fmt(taken)}'
                                    : 'Tomado: --',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (taken != null && delaySecs > 0) ...[
                                const SizedBox(width: 10),
                                Text(
                                  'Atraso: ${delaySecs ~/ 60} min',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
