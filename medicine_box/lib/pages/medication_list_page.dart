import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medicine_box/models/enum/mqtt_type_action_enum.dart';
import 'package:medicine_box/models/medication_alarm_details.dart';
import 'package:medicine_box/models/medication_history.dart';
import 'package:medicine_box/models/mqtt_action_message.dart';
import 'package:medicine_box/models/next_user_alarm.dart';
import 'package:medicine_box/models/profile_model.dart';
import 'package:medicine_box/services/log_service.dart';
import 'package:medicine_box/services/medication_schedule_service.dart';
import 'package:medicine_box/services/profile_service.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import '../services/mqtt_service.dart';
import 'medication_form_page.dart';
import 'invite_caregiver_page.dart';
import '../services/auth_service.dart';
import 'sign_in_page.dart';
import 'profile_page.dart';

class MedicationListPage extends StatefulWidget {
  const MedicationListPage({super.key});
  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

enum _MenuAction { profile, logout }

class _MedicationListPageState extends State<MedicationListPage> {
  final _medSvc = MedicationService();
  final _profileSvc = ProfileService();
  final _medScheduleSvc = MedicationScheduleService();
  final _mqtt = MqttService();
  final _log = LogService().logger;

  List<Medication> _meds = [];
  NextUserAlarm? _nextMedAlarm;
  Profile? _userProfile;
  bool _loadingMqtt = true;
  bool _loading = true;
  bool _isConnectionSuccessful = false;
  Timer? _checkTimer;
  DateTime? _lastAlarmTime;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    Stopwatch stopWatch = Stopwatch();

    _log.i("[MLP] - Incializando a main page de medicações");
    if (mounted) setState(() => _loadingMqtt = true);

    _log.i("[MLP] - Incializando conexão com o Broker MQTT...");
    stopWatch.start();
    _mqtt
        .connect()
        .then((result) {
          stopWatch.stop();
          _log.i(
            '[MLP] - Conexão MQTT finalizada em ${stopWatch.elapsedMilliseconds} ms',
          );
          if (mounted) {
            setState(() {
              _loadingMqtt = false;
              _isConnectionSuccessful = result;
            });
          }
          _listenMqtt();
        })
        .catchError((e) {
          stopWatch.stop();
          _log.w(
            '[MLP] - Conexão MQTT finalizada com erro em ${stopWatch.elapsedMilliseconds} ms',
          );
          if (mounted) {
            setState(() {
              _loadingMqtt = false;
              _isConnectionSuccessful = false;
            });
          }
        });

    await _reload();
    _startAlarmLoop();
  }

  void _listenMqtt() {
    _log.i("[MLP] - Inicializando listener de mensagens do MQTT");

    _mqtt.alarmMessagesStream.listen((msg) async {
      try {
        _log.i("[MLP] - Mensagem de alarme recebida do MQTT: ${msg.toJson()}");
      } catch (e) {
        _log.e(
          "[MLP] - Erro ao processar mensagem de alarme recebida do MQTT",
          error: e,
        );
      }
    });
  }

  void _startAlarmLoop() {
    _checkTimer?.cancel();
    _log.i("[MLP] - Iniciando o loop de verificação de alarmes");
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAlarms();
    });
  }

  Future<void> _checkAlarms() async {
    _log.i("[MLP] - Verificando alarmes");
    final now = DateTime.now();
    await _getNextMedication();

    if (_nextMedAlarm == null) return;

    final diff = now.difference(_nextMedAlarm!.scheduled_at);

    if (diff.abs() < const Duration(minutes: 1)) {
      _log.i(
        "[MLP] - Alarme disparado: $_nextMedAlarm - usuário: ${_nextMedAlarm!.userId}",
      );
      if (_lastAlarmTime != null &&
          now.difference(_lastAlarmTime!).inMinutes < 5) {
        _log.i("[MLP] - Alarme já disparado recentemente. Ignorando...");
        return;
      }

      if (_isConnectionSuccessful) {
        _log.i("[MLP] - Enviando comando de ativação do alarme para o MQTT");
        final msg =
            MqttActionMessage(
              type: MqttActionTypeEnum.activateAlarm,
              source: '',
              target: '',
              metadata: {
                "userId": _nextMedAlarm!.userId,
                "medications":
                    _nextMedAlarm!.medicationAlarmDetails
                        .map((e) => e.toMap())
                        .toList(),
              },
            ).toJsonString();
        _log.d("[MLP] - Enviando comando MQTT: $msg");

        _mqtt.sendAlarmCommand(msg, _nextMedAlarm!.userId);
      }

      _lastAlarmTime = now;
      return;
    }
  }

  Future<void> _getNextMedication() async {
    _log.i("[MLP] - Buscando a próxima medicação do usuário");
    try {
      List<MedicationHistory>? nextMedAlarmResult;
      _log.i(
        "[MLP] - Verificando se já há um alarme existente: $_nextMedAlarm",
      );

      _nextMedAlarm == null
          ? nextMedAlarmResult = await _medScheduleSvc.getUserNextMedication(
            _nextMedAlarm?.scheduled_at,
          )
          : nextMedAlarmResult = null;

      if (nextMedAlarmResult != null && nextMedAlarmResult.isNotEmpty) {
        final meds = await _medSvc.getById(
          nextMedAlarmResult.map((e) => e.medicationId).toList(),
        );

        if (meds == null || meds.isEmpty) {
          _log.e(
            "[MLP] - Não foram encontrados os detalhes dos medicamentos salvos para o próximo alarme",
          );
          throw Exception("Medicações não encontradas para o próximo alarme.");
        }

        final listMedNames =
            nextMedAlarmResult.map((e) {
              final med = meds.firstWhere(
                (m) => m.id == e.medicationId,
                orElse:
                    () =>
                        throw Exception(
                          "Medicação não encontrada para ID ${e.medicationId}",
                        ),
              );
              return med.name;
            }).toList();

        _nextMedAlarm = NextUserAlarm(
          userId: nextMedAlarmResult[0].userId,
          medicationAlarmDetails:
              nextMedAlarmResult.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return MedicationAlarmDetails(
                  id: e.id,
                  medicationId: e.medicationId,
                  name: listMedNames[idx],
                );
              }).toList(),
          scheduled_at: nextMedAlarmResult[0].scheduled_at,
        );
      }

      if (_nextMedAlarm != null) {
        final diff = DateTime.now().difference(_nextMedAlarm!.scheduled_at);

        if (diff > const Duration(minutes: 15)) {
          for (final medDetail in _nextMedAlarm!.medicationAlarmDetails) {
            await _medScheduleSvc.updateMedicationStatus(
              medDetail.id,
              "Missed",
              null,
            );
          }
          _nextMedAlarm = null;
          await _getNextMedication();
        }
      }

      if (mounted) {
        setState(() {
          _nextMedAlarm = _nextMedAlarm;
        });
      }
    } catch (e) {
      _log.e("[MLP] - Erro ao buscar a próxima medicação do usuário", error: e);
      throw Exception("Erro ao buscar a próxima medicação");
    }
  }

  Future<void> _reload() async {
    _log.i("[MLP] - Carregando a página de medicações");
    if (mounted) setState(() => _loading = true);

    _userProfile = await _profileSvc.getOwnProfile();
    final meds = await _medSvc.getAll();
    await _getNextMedication();
    _meds = meds;

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveNewMedication(Medication newMed) async {
    final medResult = await _medSvc.upsert(newMed);

    final med = medResult.data!;

    await _medScheduleSvc.upsertMedicationSchedule(
      med.id ?? '',
      newMed.startDate ?? DateTime.now(),
      newMed.endDate ?? DateTime.now().add(const Duration(days: 30)),
      newMed.days,
      newMed.schedules,
    );

    await _reload();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _mqtt.disconnect();
    super.dispose();
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    return '${_pad2(dt.day)}/${_pad2(dt.month)} ${_pad2(dt.hour)}:${_pad2(dt.minute)}';
  }

  Widget _buildNextMedicationCard(BuildContext context) {
    final alarm = _nextMedAlarm;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            alarm == null
                ? const ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('PRÓXIMA MEDICAÇÃO'),
                  subtitle: Text('Nenhuma medicação próxima.'),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRÓXIMA MEDICAÇÃO',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.medication, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alarm.medicationAlarmDetails
                                .map((d) => d.name)
                                .join('\n'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateTime(alarm.scheduled_at),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildMedicationListBody(BuildContext context) {
    return _meds.isEmpty
        ? const Center(child: Text('Nenhuma medicação cadastrada.'))
        : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _meds.length,
          itemBuilder: (_, i) {
            final m = _meds[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Exibindo a dosagem
                    Text(
                      'Dosagem: ${m.dosage ?? 'Não especificada'}', // Exibindo a dosagem
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children:
                          m.days.map((d) => Chip(label: Text(d))).toList(),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children:
                          m.schedules.map((s) => Chip(label: Text(s))).toList(),
                    ),
                    if (m.startDate != null || m.endDate != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Período: ${m.startDate != null ? "${m.startDate!.day}/${m.startDate!.month}" : "..."} '
                        'até ${m.endDate != null ? "${m.endDate!.day}/${m.endDate!.month}" : "..."}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => MedicationFormPage(
                                      medication: m,
                                      onSave: (updated) async {
                                        await _medSvc.upsert(updated);
                                        _nextMedAlarm = null;
                                        await _reload();
                                      },
                                    ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text('Confirmar exclusão'),
                                    content: const Text(
                                      'Deseja realmente excluir esta medicação?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              await _medSvc.delete(m.id!);
                              await _reload();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Future<void> _handleMenu(_MenuAction action) async {
    switch (action) {
      case _MenuAction.profile:
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      case _MenuAction.logout:
        try {
          await AuthService()
              .signOut(); // ou Supabase.instance.client.auth.signOut()
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao sair: $e')));
        } finally {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (_) => false,
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Medicações',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: _handleMenu,
            itemBuilder:
                (ctx) => const [
                  PopupMenuItem(
                    value: _MenuAction.profile,
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Perfil'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.logout,
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sair'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _loadingMqtt
                        ? const Icon(Icons.sync, color: Colors.orange)
                        : _isConnectionSuccessful
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.close, color: Colors.red),
                    const SizedBox(width: 6),
                    _loadingMqtt
                        ? const Text(
                          "Conectando...",
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        )
                        : _isConnectionSuccessful
                        ? const Text(
                          "Conectado",
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        )
                        : const Text(
                          "Falha na conexão",
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                  ],
                ),
                Row(
                  children: [
                    _userProfile?.caregiverId == null ||
                            _userProfile!.caregiverId!.isEmpty
                        ? IconButton(
                          icon: const Icon(Icons.person_add),
                          tooltip: "Adicionar cuidador",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InviteCaregiverPage(),
                              ),
                            );
                          },
                        )
                        : IconButton(
                          icon: const Icon(Icons.person),
                          tooltip: "Ver cuidador",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InviteCaregiverPage(),
                              ),
                            );
                          },
                        ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Adicionar Medicação',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => MedicationFormPage(
                                  onSave: (newMed) async {
                                    await _saveNewMedication(newMed);
                                    _nextMedAlarm = null;
                                    await _reload();
                                  },
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _meds.isEmpty
                      ? Container()
                      : _buildNextMedicationCard(context),
                  const SizedBox(height: 8),
                  Expanded(child: _buildMedicationListBody(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
