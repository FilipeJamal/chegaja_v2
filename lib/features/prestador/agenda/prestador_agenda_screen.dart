
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/repositories/prestador_repo.dart';

class PrestadorAgendaScreen extends StatefulWidget {
  const PrestadorAgendaScreen({super.key});

  @override
  State<PrestadorAgendaScreen> createState() => _PrestadorAgendaScreenState();
}

class _PrestadorAgendaScreenState extends State<PrestadorAgendaScreen> {
  final PrestadorRepo _repo = PrestadorRepo();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  bool _isLoading = true;

  // Estado local da agenda: Dia -> [Start, End] (simplificado para 1 intervalo por dia por agora)
  // Ex: 'monday': ['09:00', '18:00']
  final Map<String, List<String>> _workingHours = {};

  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final p = await _repo.getPrestador(_uid);
    if (p != null) {
      // Deep copy ou init
      _workingHours.clear();
      _workingHours.addAll(p.workingHours);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await _repo.updateAgenda(_uid, workingHours: _workingHours);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda atualizada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateDay(String day) {
    switch (day) {
      case 'monday': return 'Segunda-feira';
      case 'tuesday': return 'Terça-feira';
      case 'wednesday': return 'Quarta-feira';
      case 'thursday': return 'Quinta-feira';
      case 'friday': return 'Sexta-feira';
      case 'saturday': return 'Sábado';
      case 'sunday': return 'Domingo';
      default: return day;
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_workingHours.containsKey(day)) {
        _workingHours.remove(day);
      } else {
        // Default hours
        _workingHours[day] = ['09:00', '18:00'];
      }
    });
  }

  Future<void> _pickTime(String day, int index) async {
    final currentStr = _workingHours[day]![index];
    final parts = currentStr.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        _workingHours[day]![index] = '$h:$m';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Defina os seus horários de atendimento.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ..._daysOfWeek.map((day) {
                  final isActive = _workingHours.containsKey(day);
                  final times = _workingHours[day];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: isActive,
                                onChanged: (_) => _toggleDay(day),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _translateDay(day),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (isActive && times != null && times.length >= 2) ...[
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _TimeChip(
                                  label: 'Início',
                                  time: times[0],
                                  onTap: () => _pickTime(day, 0),
                                ),
                                const Icon(Icons.arrow_forward, color: Colors.grey),
                                _TimeChip(
                                  label: 'Fim',
                                  time: times[1],
                                  onTap: () => _pickTime(day, 1),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
