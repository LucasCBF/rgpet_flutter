// lib/screens/tela_agendamento_dono.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:rgpet/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class TelaAgendamentoDono extends StatefulWidget {
  const TelaAgendamentoDono({super.key});

  @override
  State<TelaAgendamentoDono> createState() => _TelaAgendamentoDonoState();
}

class _TelaAgendamentoDonoState extends State<TelaAgendamentoDono> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _motivoController = TextEditingController();

  String? _selectedPetId;
  String? _selectedVeterinarioId;
  String? _selectedProcedure;
  DateTime? _selectedDay;
  String? _selectedHorarioId;

  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _veterinarios = [];

  Map<DateTime, List<DocumentSnapshot>> _horariosPorDia = {};
  List<DocumentSnapshot> _horariosDoDia = [];

  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, int> _procedureDurations = {
    'Consulta': 60, // minutos
    'Vacinação': 30, // minutos
    'Higiene Bucal': 60, // minutos
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Usuário não logado.';
        _isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot petsSnapshot = await FirebaseFirestore.instance
          .collection('donos')
          .doc(user.uid)
          .collection('pets')
          .get();
      _pets = petsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'nome': data['nome']};
      }).toList();

      QuerySnapshot veterinariosSnapshot = await FirebaseFirestore.instance
          .collection('veterinarios')
          .get();
      _veterinarios = veterinariosSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'nome': data['nomeCompleto']};
      }).toList();

      setState(() {
        _isLoading = false;
        if (_pets.isNotEmpty) {
          _selectedPetId = _pets.first['id'];
        }
        if (_veterinarios.isNotEmpty) {
          _selectedVeterinarioId = _veterinarios.first['id'];
          _loadHorariosVeterinario(_selectedVeterinarioId!);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHorariosVeterinario(String veterinarioId) async {
    setState(() {
      _horariosPorDia = {};
      _selectedDay = null;
      _horariosDoDia = [];
      _selectedHorarioId = null;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('horariosDisponiveis')
          .where('veterinarioId', isEqualTo: veterinarioId)
          .where('isAgendado', isEqualTo: false)
          .where('isBloqueado', isEqualTo: false)
          .orderBy('timestamp', descending: false)
          .get();

      final Map<DateTime, List<DocumentSnapshot>> tempHorarios = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
        final DateTime day = DateTime.utc(timestamp.year, timestamp.month, timestamp.day);

        if (!tempHorarios.containsKey(day)) {
          tempHorarios[day] = [];
        }
        tempHorarios[day]!.add(doc);
      }
      setState(() {
        _horariosPorDia = tempHorarios;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar horários: ${e.toString()}')),
        );
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_horariosPorDia.containsKey(selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _horariosDoDia = _horariosPorDia[selectedDay]!;
        _selectedHorarioId = null;
      });
    } else {
      setState(() {
        _selectedDay = null;
        _horariosDoDia = [];
        _selectedHorarioId = null;
      });
    }
  }

  Future<void> _agendarConsulta() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPetId == null || _selectedVeterinarioId == null || _selectedProcedure == null || _selectedHorarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.')),
        );
        return;
      }
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não logado.')));
          return;
        }

        // NOVO: Busca os nomes do pet e do dono
        final petDoc = await FirebaseFirestore.instance.collection('donos').doc(user.uid).collection('pets').doc(_selectedPetId).get();
        final donoDoc = await FirebaseFirestore.instance.collection('donos').doc(user.uid).get();

        final String petNome = petDoc.data()?['nome'] ?? 'Nome do Pet não encontrado';
        final String donoNome = donoDoc.data()?['nomeCompleto'] ?? 'Nome do Dono não encontrado';

        final selectedHorarioDoc = await FirebaseFirestore.instance
            .collection('horariosDisponiveis')
            .doc(_selectedHorarioId)
            .get();
        final selectedHorarioData = selectedHorarioDoc.data() as Map<String, dynamic>;
        final Timestamp timestamp = selectedHorarioData['timestamp'];
        final DateTime dataHoraConsulta = timestamp.toDate();

        final int durationInMinutes = _procedureDurations[_selectedProcedure]!;
        List<String> horariosParaAgendar = [_selectedHorarioId!];

        if (durationInMinutes == 60) {
          final nextHorario = _horariosDoDia.firstWhere(
            (doc) {
              final nextTimestamp = (doc.data() as Map<String, dynamic>)['timestamp'].toDate();
              return nextTimestamp.isAtSameMomentAs(dataHoraConsulta.add(const Duration(minutes: 30))) &&
                     doc['isAgendado'] == false;
            },
            orElse: () => throw 'Próximo horário não disponível para a duração do procedimento.',
          );
          horariosParaAgendar.add(nextHorario.id);
        }

        DocumentReference consultaRef = await FirebaseFirestore.instance.collection('consultas').add({
          'donoUid': user.uid,
          'donoNome': donoNome, // NOVO: Salva o nome do dono
          'petId': _selectedPetId,
          'petNome': petNome, // NOVO: Salva o nome do pet
          'veterinarioId': _selectedVeterinarioId,
          'dataHoraConsulta': dataHoraConsulta,
          'motivoConsulta': _motivoController.text.trim(),
          'procedimento': _selectedProcedure,
          'status': 'pendente',
          'dataAgendamento': FieldValue.serverTimestamp(),
          'horariosAgendadosIds': horariosParaAgendar,
        });

        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (String horarioId in horariosParaAgendar) {
          batch.update(
            FirebaseFirestore.instance.collection('horariosDisponiveis').doc(horarioId),
            {
              'isAgendado': true,
              'donoUidAgendamento': user.uid,
              'petIdAgendamento': _selectedPetId,
              'consultaId': consultaRef.id,
            },
          );
        }
        await batch.commit();

        await FirebaseFirestore.instance.collection('notificacoesVeterinario').add({
          'veterinarioId': _selectedVeterinarioId,
          'donoUid': user.uid,
          'petId': _selectedPetId,
          'tipo': 'nova_consulta',
          'mensagem': 'Nova solicitação de consulta (${_selectedProcedure}) para ${DateFormat('dd/MM/yyyy HH:mm').format(dataHoraConsulta)}.',
          'lida': false,
          'timestamp': FieldValue.serverTimestamp(),
          'consultaId': consultaRef.id,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Consulta agendada com sucesso!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (e is String) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao agendar consulta: ${e.toString()}')));
        }
      }
    }
  }

  bool _checkAvailability(DateTime startTime, int duration) {
    if (duration == 30) {
      return true;
    }
    final nextSlotTime = startTime.add(const Duration(minutes: 30));
    return _horariosDoDia.any((doc) {
      final Timestamp nextTimestamp = (doc.data() as Map<String, dynamic>)['timestamp'];
      return nextTimestamp.toDate().isAtSameMomentAs(nextSlotTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Consulta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdown(
                'Selecione o Pet:',
                _pets.map((p) => {'id': p['id'], 'nome': p['nome']}).toList(),
                _selectedPetId,
                (value) => setState(() => _selectedPetId = value),
              ),
              const SizedBox(height: 20),

              _buildDropdown(
                'Selecione o Veterinário:',
                _veterinarios.map((v) => {'id': v['id'], 'nome': v['nome']}).toList(),
                _selectedVeterinarioId,
                (value) {
                  setState(() {
                    _selectedVeterinarioId = value;
                    if (value != null) {
                      _loadHorariosVeterinario(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              Text('Selecione o Procedimento:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedProcedure,
                dropdownColor: Theme.of(context).cardColor,
                items: _procedureDurations.keys.map((proc) => DropdownMenuItem(value: proc, child: Text(proc))).toList(),
                onChanged: (value) => setState(() {
                  _selectedProcedure = value;
                  _selectedHorarioId = null;
                }),
                validator: (value) => value == null ? 'Selecione um procedimento' : null,
              ),
              const SizedBox(height: 20),

              _buildCalendar(),
              const SizedBox(height: 20),

              if (_selectedDay != null && _horariosDoDia.isNotEmpty) ...[
                Text('Horários disponíveis em ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _horariosDoDia.length,
                  itemBuilder: (context, index) {
                    final horarioDoc = _horariosDoDia[index];
                    final Timestamp timestamp = (horarioDoc.data() as Map<String, dynamic>)['timestamp'];
                    final DateTime time = timestamp.toDate();
                    final String horarioTexto = DateFormat('HH:mm').format(time);
                    final bool isSelected = _selectedHorarioId == horarioDoc.id;
                    
                    final duration = _selectedProcedure != null ? _procedureDurations[_selectedProcedure]! : 0;
                    final isAvailable = _checkAvailability(time, duration);

                    if (!isAvailable) {
                      return const SizedBox();
                    }

                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedHorarioId = isSelected ? null : horarioDoc.id;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.redAccent : Theme.of(context).cardColor,
                        foregroundColor: isSelected ? Colors.white : Colors.white70,
                      ),
                      child: Text(horarioTexto),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),

              CustomTextField(
                controller: _motivoController,
                hintText: 'Detalhe o motivo da visita.',
                labelText: 'Mais Informações',
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: 'Agendar',
                backgroundColor: const Color(0xFFFDC03D),
                onPressed: _agendarConsulta,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, String? selectedValue, Function(String?) onChanged) {
    if (items.isEmpty) {
      return Center(child: Text(label, style: Theme.of(context).textTheme.bodyLarge));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          dropdownColor: Theme.of(context).cardColor,
          items: items.map<DropdownMenuItem<String>>((item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(item['nome']!, style: Theme.of(context).textTheme.bodyLarge),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Selecione a Data:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TableCalendar(
          focusedDay: _selectedDay ?? DateTime.now(),
          firstDay: DateTime.now(),
          lastDay: DateTime.utc(2030, 1, 31),
          locale: 'pt_BR',
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          onPageChanged: (focusedDay) {
            
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final hasEvents = _horariosPorDia.containsKey(DateTime.utc(day.year, day.month, day.day));
              final isSelected = isSameDay(_selectedDay, day);

              return Container(
                margin: const EdgeInsets.all(6.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.redAccent : (hasEvents ? Colors.grey[800] : Colors.grey[800]?.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: hasEvents || isSelected ? Colors.white : Colors.white38,
                  ),
                ),
              );
            },
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white),
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
          calendarStyle: CalendarStyle(
            weekendTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
            defaultTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}