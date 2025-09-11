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

  // Variáveis para armazenar as seleções do usuário
  String? _selectedPetId;
  String? _selectedVeterinarioId;
  String? _selectedProcedure; // NOVO: Procedimento selecionado
  DateTime? _selectedDay; // NOVO: Dia selecionado no calendário
  String? _selectedHorarioId; // ID do horário selecionado

  // Listas para popular os Dropdowns
  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _veterinarios = [];

  // NOVO: Horários disponíveis para o veterinário selecionado
  Map<DateTime, List<DocumentSnapshot>> _horariosPorDia = {};
  // NOVO: Lista de horários para o dia selecionado
  List<DocumentSnapshot> _horariosDoDia = [];

  bool _isLoading = true;
  String? _errorMessage;

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
      // Carregar pets do dono logado
      QuerySnapshot petsSnapshot = await FirebaseFirestore.instance
          .collection('donos')
          .doc(user.uid)
          .collection('pets')
          .get();
      _pets = petsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'nome': data['nome']};
      }).toList();

      // Carregar todos os veterinários
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
          // Inicia o carregamento dos horários do primeiro veterinário
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

  // NOVO: Carrega todos os horários disponíveis de um veterinário
  Future<void> _loadHorariosVeterinario(String veterinarioId) async {
    setState(() {
      _horariosPorDia = {}; // Limpa os horários anteriores
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

  // NOVO: Lógica para selecionar um dia no calendário
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_horariosPorDia.containsKey(selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _horariosDoDia = _horariosPorDia[selectedDay]!;
        _selectedHorarioId = null; // Reseta o horário selecionado
      });
    } else {
      // Se o dia não tem horários, limpa a lista e a seleção
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

        // 1. Obter os detalhes do horário selecionado
        final selectedHorarioDoc = await FirebaseFirestore.instance
            .collection('horariosDisponiveis')
            .doc(_selectedHorarioId)
            .get();
        final selectedHorarioData = selectedHorarioDoc.data() as Map<String, dynamic>;
        final Timestamp timestamp = selectedHorarioData['timestamp'];
        final DateTime dataHoraConsulta = timestamp.toDate();

        // 2. Criar o documento da consulta
        DocumentReference consultaRef = await FirebaseFirestore.instance.collection('consultas').add({
          'donoUid': user.uid,
          'petId': _selectedPetId,
          'veterinarioId': _selectedVeterinarioId,
          'dataHoraConsulta': dataHoraConsulta,
          'motivoConsulta': _motivoController.text.trim(),
          'procedimento': _selectedProcedure, // NOVO: Salva o procedimento
          'status': 'pendente',
          'dataAgendamento': FieldValue.serverTimestamp(),
          'horarioDisponivelId': _selectedHorarioId,
        });

        // 3. Atualizar o horário disponível para marcar como agendado
        await FirebaseFirestore.instance.collection('horariosDisponiveis').doc(_selectedHorarioId).update({
          'isAgendado': true,
          'donoUidAgendamento': user.uid,
          'petIdAgendamento': _selectedPetId,
          'consultaId': consultaRef.id,
        });

        // 4. Criar notificação para o veterinário
        await FirebaseFirestore.instance.collection('notificacoesVeterinario').add({
          'veterinarioId': _selectedVeterinarioId,
          'donoUid': user.uid,
          'petId': _selectedPetId,
          'tipo': 'nova_consulta',
          'mensagem': 'Nova solicitação de consulta para ${DateFormat('dd/MM/yyyy HH:mm').format(dataHoraConsulta)}.',
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao agendar consulta: ${e.toString()}')),
          );
        }
      }
    }
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
              // Dropdown para o Pet
              _buildDropdown('Selecione o Pet:', _pets, (value) => setState(() => _selectedPetId = value)),
              const SizedBox(height: 20),

              // Dropdown para o Veterinário
              _buildDropdown('Selecione o Veterinário:', _veterinarios, (value) {
                setState(() {
                  _selectedVeterinarioId = value;
                  if (value != null) {
                    _loadHorariosVeterinario(value);
                  }
                });
              }),
              const SizedBox(height: 20),

              // NOVO: Dropdown para o Procedimento
              Text('Selecione o Procedimento:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedProcedure,
                decoration: InputDecoration(
                  hintText: 'Procedimento',
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                ),
                dropdownColor: Theme.of(context).cardColor,
                items: ['Consulta', 'Vacinação', 'Higiene Bucal']
                    .map((proc) => DropdownMenuItem(value: proc, child: Text(proc))).toList(),
                onChanged: (value) => setState(() => _selectedProcedure = value),
                validator: (value) => value == null ? 'Selecione um procedimento' : null,
              ),
              const SizedBox(height: 20),

              // Calendário para selecionar o dia
              _buildCalendar(),
              const SizedBox(height: 20),

              // NOVO: Grade de horários do dia selecionado
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
                    final String horarioTexto = DateFormat('HH:mm').format(timestamp.toDate());
                    final bool isSelected = _selectedHorarioId == horarioDoc.id;

                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedHorarioId = isSelected ? null : horarioDoc.id;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.redAccent : Theme.of(context).cardColor,
                        foregroundColor: isSelected ? Colors.white : Colors.white70,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(horarioTexto),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),

              // Campo de "Mais Informações"
              CustomTextField(
                controller: _motivoController,
                hintText: 'Mais informações sobre a consulta',
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

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items, Function(String?) onChanged) {
    if (items.isEmpty) {
      return Center(child: Text(label, style: Theme.of(context).textTheme.bodyLarge));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.first['id'],
          decoration: InputDecoration(
            hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          ),
          dropdownColor: Theme.of(context).cardColor,
          items: items.map<DropdownMenuItem<String>>((item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(item['nome']!),
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
            // Pode ser usado para carregar mais horários se necessário
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final hasEvents = _horariosPorDia.containsKey(DateTime.utc(day.year, day.month, day.day));
              final isToday = isSameDay(day, DateTime.now());
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