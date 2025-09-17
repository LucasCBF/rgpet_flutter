import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class TelaGerenciarHorariosVeterinario extends StatefulWidget {
  const TelaGerenciarHorariosVeterinario({super.key});

  @override
  State<TelaGerenciarHorariosVeterinario> createState() => _TelaGerenciarHorariosVeterinarioState();
}

class _TelaGerenciarHorariosVeterinarioState extends State<TelaGerenciarHorariosVeterinario> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _veterinarioId;
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadVeterinarioId();
  }

  Future<void> _loadVeterinarioId() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Usuário não logado.';
        _isLoading = false;
      });
      return;
    }
    _veterinarioId = user.uid;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF1E1E2C), body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(backgroundColor: const Color(0xFF1E1E2C), body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Gerenciar Agenda', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Horários Agendados:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('horariosDisponiveis').where('veterinarioId', isEqualTo: _veterinarioId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final eventos = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                
                final Map<DateTime, List<dynamic>> horariosPorDia = {};
                for (var horario in eventos) {
                  final DateTime timestamp = (horario['timestamp'] as Timestamp).toDate();
                  final DateTime day = DateTime.utc(timestamp.year, timestamp.month, timestamp.day);
                  if (!horariosPorDia.containsKey(day)) {
                    horariosPorDia[day] = [];
                  }
                  horariosPorDia[day]!.add(horario);
                }

                return TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.now(),
                  lastDay: DateTime.utc(2030, 1, 31),
                  locale: 'pt_BR',
                  onDaySelected: (day, focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final hasAgendado = horariosPorDia[day]?.any((h) => h['isAgendado'] == true) ?? false;
                      final hasBloqueado = horariosPorDia[day]?.any((h) => h['isBloqueado'] == true) ?? false;
                      final hasDisponivel = horariosPorDia[day]?.any((h) => h['isAgendado'] == false && h['isBloqueado'] == false) ?? false;
                      
                      Color color;
                      if (hasAgendado) {
                        color = Colors.green[800]!;
                      } else if (hasBloqueado) {
                        color = Colors.red[800]!;
                      } else if (hasDisponivel) {
                        color = Colors.grey[800]!;
                      } else {
                        color = Colors.grey[800]!.withValues();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.all(6.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.0)),
                        child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDC03D),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GerarHorariosScreen()),
                );
              },
              child: const Text('Gerar Horários', style: TextStyle(fontSize: 18, color: Color(0xFF1E1E2C))),
            ),
          ],
        ),
      ),
    );
  }
}

// NOVA TELA: GerarHorariosScreen
class GerarHorariosScreen extends StatefulWidget {
  const GerarHorariosScreen({super.key});

  @override
  State<GerarHorariosScreen> createState() => _GerarHorariosScreenState();
}

class _GerarHorariosScreenState extends State<GerarHorariosScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _veterinarioId;

  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.enforced;

  final Set<int> _selectedDaysOfWeek = {}; // 1 = Seg, 7 = Dom
  final List<String> _diasDaSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  TimeOfDay? _inicioJornada;
  TimeOfDay? _fimJornada;

  // NOVO: Apenas uma pausa com início e fim
  TimeOfDay? _inicioPausa;
  TimeOfDay? _fimPausa;

  @override
  void initState() {
    super.initState();
    _veterinarioId = _auth.currentUser?.uid;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      if (_rangeStart != null && _rangeEnd == null) {
        _rangeEnd = selectedDay;
        if (_rangeEnd!.isBefore(_rangeStart!)) {
          final temp = _rangeStart;
          _rangeStart = _rangeEnd;
          _rangeEnd = temp;
        }
      } else {
        _rangeStart = selectedDay;
        _rangeEnd = null;
      }
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDaysOfWeek.contains(day)) {
        _selectedDaysOfWeek.remove(day);
      } else {
        _selectedDaysOfWeek.add(day);
      }
    });
  }
  
  Future<void> _gerarHorarios() async {
    if (_veterinarioId == null || _rangeStart == null || _rangeEnd == null || _inicioJornada == null || _fimJornada == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos obrigatórios.')));
      return;
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando horários...')));

    final int duracaoSlotMinutos = 30;

    for (var dia = _rangeStart!; dia.isBefore(_rangeEnd!.add(const Duration(days: 1))); dia = dia.add(const Duration(days: 1))) {
      if (!_selectedDaysOfWeek.contains(dia.weekday)) {
        continue;
      }
      
      final DateTime inicioDia = DateTime(dia.year, dia.month, dia.day, _inicioJornada!.hour, _inicioJornada!.minute);
      final DateTime fimDia = DateTime(dia.year, dia.month, dia.day, _fimJornada!.hour, _fimJornada!.minute);
      
      DateTime horaAtual = inicioDia;
      while (horaAtual.isBefore(fimDia)) {
        bool isPausa = (_inicioPausa != null && _fimPausa != null) &&
            (horaAtual.isAfter(DateTime(dia.year, dia.month, dia.day, _inicioPausa!.hour, _inicioPausa!.minute)) &&
             horaAtual.isBefore(DateTime(dia.year, dia.month, dia.day, _fimPausa!.hour, _fimPausa!.minute)));
        
        if (!isPausa) {
          final existingDocs = await _firestore.collection('horariosDisponiveis').where('veterinarioId', isEqualTo: _veterinarioId).where('timestamp', isEqualTo: Timestamp.fromDate(horaAtual)).limit(1).get();
          if (existingDocs.docs.isEmpty) {
            await _firestore.collection('horariosDisponiveis').add({
              'veterinarioId': _veterinarioId,
              'timestamp': Timestamp.fromDate(horaAtual),
              'isAgendado': false,
              'isBloqueado': false,
            });
          }
        }
        horaAtual = horaAtual.add(Duration(minutes: duracaoSlotMinutos));
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horários gerados com sucesso!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Gerar Horários', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('1. Selecione o período:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.now(),
              lastDay: DateTime.utc(2030, 1, 31),
              locale: 'pt_BR',
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: _rangeSelectionMode,
              onDaySelected: _onDaySelected,
            ),
            const SizedBox(height: 24),
            const Text('2. Selecione os dias da semana:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: List.generate(_diasDaSemana.length, (index) {
                final int weekday = index + 1; // 1 = Seg, 7 = Dom
                final bool isSelected = _selectedDaysOfWeek.contains(weekday);
                return ActionChip(
                  label: Text(_diasDaSemana[index]),
                  backgroundColor: isSelected ? Colors.redAccent : Colors.grey[700],
                  onPressed: () => _toggleDay(weekday),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('3. Defina o intervalo de atendimento:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTimePickerField('Início', _inicioJornada, (time) => setState(() => _inicioJornada = time))),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePickerField('Fim', _fimJornada, (time) => setState(() => _fimJornada = time))),
              ],
            ),
            const SizedBox(height: 24),
            // NOVO: O formato do item 4
            const Text('4. Defina o intervalo de pausa:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTimePickerField('Início', _inicioPausa, (time) => setState(() => _inicioPausa = time))),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePickerField('Fim', _fimPausa, (time) => setState(() => _fimPausa = time))),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDC03D),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _gerarHorarios,
              child: const Text('Gerar Horários', style: TextStyle(fontSize: 18, color: Color(0xFF1E1E2C))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerField(String label, TimeOfDay? selectedTime, Function(TimeOfDay?) onTap) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
        if (picked != null) onTap(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(selectedTime?.format(context) ?? 'Selecionar', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}