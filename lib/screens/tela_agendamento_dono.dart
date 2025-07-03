// lib/screens/tela_agendamento_dono.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:rgpet/widgets/custom_text_field.dart';
import 'package:intl/intl.dart'; // Importe intl

class TelaAgendamentoDono extends StatefulWidget {
  const TelaAgendamentoDono({super.key});

  @override
  State<TelaAgendamentoDono> createState() => _TelaAgendamentoDonoState();
}

class _TelaAgendamentoDonoState extends State<TelaAgendamentoDono> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos do formulário
  final TextEditingController _motivoController = TextEditingController();

  // Variáveis para armazenar o pet, veterinário e HORÁRIO DISPONÍVEL selecionados
  String? _selectedPetId;
  String? _selectedVeterinarioId;
  String? _selectedHorarioId; // NOVO: ID do horário disponível selecionado

  // Listas para popular os Dropdowns
  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _veterinarios = [];
  List<Map<String, dynamic>> _horariosDisponiveisVeterinario = []; // NOVO: Horários do veterinário selecionado

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Carrega pets do dono e veterinários
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
          _selectedPetId = _pets.first['id']; // Seleciona o primeiro pet por padrão
        }
        if (_veterinarios.isNotEmpty) {
          _selectedVeterinarioId = _veterinarios.first['id']; // Seleciona o primeiro vet por padrão
          _loadHorariosVeterinario(_selectedVeterinarioId!); // Carrega horários do primeiro vet
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao carregar pets ou veterinários: $e');
    }
  }

  // NOVO: Carrega horários disponíveis para o veterinário selecionado
  Future<void> _loadHorariosVeterinario(String veterinarioId) async {
    setState(() {
      _horariosDisponiveisVeterinario = []; // Limpa a lista anterior
      _selectedHorarioId = null; // Reseta a seleção de horário
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('horariosDisponiveis')
          .where('veterinarioId', isEqualTo: veterinarioId)
          .where('isAgendado', isEqualTo: false) // Apenas horários não agendados
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _horariosDisponiveisVeterinario = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'data': data['data'],
            'hora': data['hora'],
            'timestamp': data['timestamp'], // Manter o timestamp para exibição/ordenacao
          };
        }).toList();
        if (_horariosDisponiveisVeterinario.isNotEmpty) {
          _selectedHorarioId = _horariosDisponiveisVeterinario.first['id'];
        }
      });
    } catch (e) {
      print('Erro ao carregar horários do veterinário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar horários do veterinário: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _agendarConsulta() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPetId == null || _selectedVeterinarioId == null || _selectedHorarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione um pet, um veterinário e um horário disponível.')),
        );
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Obter os detalhes do horário selecionado
          final selectedHorario = _horariosDisponiveisVeterinario.firstWhere(
                (horario) => horario['id'] == _selectedHorarioId,
            orElse: () => {}, // Retorna um mapa vazio se não encontrar
          );

          if (selectedHorario.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Horário selecionado inválido ou já agendado.')),
            );
            return;
          }

          // 2. Criar o documento da consulta
          DocumentReference consultaRef = await FirebaseFirestore.instance.collection('consultas').add({
            'donoUid': user.uid,
            'petId': _selectedPetId,
            'veterinarioId': _selectedVeterinarioId,
            'dataConsulta': selectedHorario['data'], // Usar data do horário disponível
            'horaConsulta': selectedHorario['hora'], // Usar hora do horário disponível
            'motivoConsulta': _motivoController.text.trim(),
            'status': 'pendente',
            'dataAgendamento': FieldValue.serverTimestamp(),
            'horarioDisponivelId': _selectedHorarioId, // Referência ao horário disponível
          });

          // 3. Atualizar o horário disponível para marcar como agendado
          await FirebaseFirestore.instance.collection('horariosDisponiveis').doc(_selectedHorarioId).update({
            'isAgendado': true,
            'donoUidAgendamento': user.uid,
            'petIdAgendamento': _selectedPetId,
            'consultaId': consultaRef.id, // Armazena o ID da consulta recém-criada
          });

          // 4. Criar notificação para o veterinário
          await FirebaseFirestore.instance.collection('notificacoesVeterinario').add({
            'veterinarioId': _selectedVeterinarioId,
            'donoUid': user.uid,
            'petId': _selectedPetId,
            'tipo': 'nova_consulta',
            'mensagem': 'Nova solicitação de consulta para ${selectedHorario['data']} às ${selectedHorario['hora']}.',
            'lida': false,
            'timestamp': FieldValue.serverTimestamp(),
            'consultaId': consultaRef.id,
          });


          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Consulta agendada com sucesso! O veterinário será notificado.')),
            );
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Usuário não logado.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao agendar consulta: ${e.toString()}')),
          );
        }
        print('Erro ao agendar consulta: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Você precisa cadastrar um pet antes de agendar uma consulta.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Cadastrar Pet',
              backgroundColor: Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({MaterialState.selected}) ?? Colors.blue,
              onPressed: () {
                Navigator.of(context).pushNamed('/cadastro_pet');
              },
            ),
          ],
        ),
      );
    }

    if (_veterinarios.isEmpty) {
      return Center(
        child: Text(
          'Não há veterinários disponíveis para agendamento no momento.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Agendar Consulta',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selecione o Pet:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPetId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                ),
                dropdownColor: Theme.of(context).cardColor,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                iconEnabledColor: Colors.white70,
                validator: (value) => value == null ? 'Selecione um pet' : null,
                items: _pets.map<DropdownMenuItem<String>>((pet) {
                  return DropdownMenuItem<String>(
                    value: pet['id'],
                    child: Text(pet['nome']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPetId = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Selecione o Veterinário:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedVeterinarioId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                ),
                dropdownColor: Theme.of(context).cardColor,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                iconEnabledColor: Colors.white70,
                validator: (value) => value == null ? 'Selecione um veterinário' : null,
                items: _veterinarios.map<DropdownMenuItem<String>>((vet) {
                  return DropdownMenuItem<String>(
                    value: vet['id'],
                    child: Text(vet['nome']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedVeterinarioId = newValue;
                    if (newValue != null) {
                      _loadHorariosVeterinario(newValue); // Carrega horários ao mudar o veterinário
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Selecione a Data e Hora:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              _horariosDisponiveisVeterinario.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _selectedVeterinarioId != null
                      ? 'Nenhum horário disponível para este veterinário.'
                      : 'Selecione um veterinário para ver os horários.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
                  : DropdownButtonFormField<String>(
                value: _selectedHorarioId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                ),
                dropdownColor: Theme.of(context).cardColor,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                iconEnabledColor: Colors.white70,
                validator: (value) => value == null ? 'Selecione um horário' : null,
                items: _horariosDisponiveisVeterinario.map<DropdownMenuItem<String>>((horario) {
                  final DateTime date = DateTime.parse(horario['data']);
                  final String formattedDate = DateFormat('dd/MM/yyyy').format(date);
                  return DropdownMenuItem<String>(
                    value: horario['id'],
                    child: Text('$formattedDate às ${horario['hora']}'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHorarioId = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _motivoController,
                hintText: 'Motivo da Consulta',
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Informe o motivo' : null,
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
}