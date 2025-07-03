// lib/screens/tela_gerenciar_horarios_veterinario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:rgpet/widgets/custom_text_field.dart';

class TelaGerenciarHorariosVeterinario extends StatefulWidget {
  const TelaGerenciarHorariosVeterinario({super.key});

  @override
  State<TelaGerenciarHorariosVeterinario> createState() => _TelaGerenciarHorariosVeterinarioState();
}

class _TelaGerenciarHorariosVeterinarioState extends State<TelaGerenciarHorariosVeterinario> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  DateTime? _selectedDate;

  String? _veterinarioId;
  // Mude para um Stream<QuerySnapshot> para ouvir em tempo real
  Stream<QuerySnapshot>? _horariosStream; // NOVO: Stream para horários

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVeterinarioIdAndSetupStream(); // Mude o nome da função
  }

  @override
  void dispose() {
    _dataController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  // Mude para configurar o stream
  Future<void> _loadVeterinarioIdAndSetupStream() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Usuário não logado.';
        _isLoading = false;
      });
      return;
    }
    _veterinarioId = user.uid;

    // Configura o stream para ouvir as mudanças em tempo real
    _horariosStream = _firestore
        .collection('horariosDisponiveis')
        .where('veterinarioId', isEqualTo: _veterinarioId)
        .orderBy('timestamp', descending: false)
        .snapshots(); // Ouve em tempo real

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2028),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.redAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A3E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E2C),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _addHorario() async {
    if (_selectedDate == null || _horaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione a data e a hora.')),
      );
      return;
    }

    if (_veterinarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID do veterinário não encontrado.')),
      );
      return;
    }

    final timeParts = _horaController.text.split(':');
    if (timeParts.length != 2 || int.tryParse(timeParts[0]) == null || int.tryParse(timeParts[1]) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de hora inválido. Use HH:MM.')),
      );
      return;
    }

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final String formattedTime = _horaController.text.trim();

    final DateTime combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    try {
      await _firestore.collection('horariosDisponiveis').add({
        'veterinarioId': _veterinarioId,
        'data': formattedDate,
        'hora': formattedTime,
        'timestamp': Timestamp.fromDate(combinedDateTime),
        'isAgendado': false,
        'donoUidAgendamento': null,
        'petIdAgendamento': null,
        'consultaId': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horário adicionado com sucesso!')),
        );
        _horaController.clear(); // Limpa o campo da hora
        // Não precisa mais chamar _loadHorariosDisponiveis(), o StreamBuilder faz isso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar horário: ${e.toString()}')),
        );
      }
      print('Erro ao adicionar horário: $e');
    }
  }

  Future<void> _removeHorario(String horarioId, bool isAgendado) async {
    if (isAgendado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível remover um horário já agendado.')),
      );
      return;
    }
    try {
      await _firestore.collection('horariosDisponiveis').doc(horarioId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horário removido com sucesso!')),
        );
        // Não precisa mais chamar _loadHorariosDisponiveis(), o StreamBuilder faz isso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover horário: ${e.toString()}')),
        );
      }
      print('Erro ao remover horário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2C),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          title: const Text('Gerenciar Horários'),
          backgroundColor: const Color(0xFF1E1E2C),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Gerenciar Horários',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Adicionar Novo Horário:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _dataController,
              hintText: 'Data',
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) => value!.isEmpty ? 'Selecione a data' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _horaController,
              hintText: 'Hora (HH:MM)',
              keyboardType: TextInputType.datetime,
              validator: (value) {
                if (value!.isEmpty) return 'Informe a hora';
                final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
                if (!regex.hasMatch(value)) return 'Formato inválido (HH:MM)';
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Adicionar Horário',
              backgroundColor: const Color(0xFFFDC03D),
              onPressed: _addHorario,
            ),
            const SizedBox(height: 40),
            Text(
              'Meus Horários Disponíveis:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Use StreamBuilder para exibir a lista de horários
            StreamBuilder<QuerySnapshot>(
              stream: _horariosStream, // Escuta o stream de horários
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar horários: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum horário disponível adicionado ainda.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Converte os documentos em uma lista para exibição
                final horarios = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'data': data['data'],
                    'hora': data['hora'],
                    'isAgendado': data['isAgendado'] ?? false,
                  };
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: horarios.length,
                  itemBuilder: (context, index) {
                    final horario = horarios[index];
                    final String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(horario['data']));
                    
                    return Card(
                      color: horario['isAgendado'] ? Colors.grey[700] : Colors.grey[800],
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          '$formattedDate às ${horario['hora']}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: horario['isAgendado'] ? Colors.white54 : Colors.white,
                            decoration: horario['isAgendado'] ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        subtitle: horario['isAgendado']
                            ? Text(
                                'Agendado',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                              )
                            : null,
                        trailing: horario['isAgendado']
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeHorario(horario['id'], horario['isAgendado']),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}