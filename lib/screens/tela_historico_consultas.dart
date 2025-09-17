// lib/screens/tela_historico_consultas.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TelaHistoricoConsultas extends StatefulWidget {
  const TelaHistoricoConsultas({super.key});

  @override
  State<TelaHistoricoConsultas> createState() => _TelaHistoricoConsultasState();
}

class _TelaHistoricoConsultasState extends State<TelaHistoricoConsultas> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _veterinarioId;
  String _nomeFiltro = '';
  DateTime? _dataFiltro;

  @override
  void initState() {
    super.initState();
    _loadVeterinarioId();
  }

  void _loadVeterinarioId() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _veterinarioId = user.uid;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataFiltro ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataFiltro) {
      setState(() {
        _dataFiltro = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_veterinarioId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Histórico de Consultas')),
        body: const Center(child: Text('Usuário não logado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Consultas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _nomeFiltro = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Filtrar por nome do pet ou dono',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'Filtrar por data',
                ),
              ],
            ),
            if (_dataFiltro != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Data selecionada: ${DateFormat('dd/MM/yyyy').format(_dataFiltro!)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _dataFiltro = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('consultas')
                    .where('veterinarioId', isEqualTo: _veterinarioId)
                    .orderBy('dataAgendamento', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Nenhuma consulta encontrada.'));
                  }

                  final consultas = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Lógica de filtro para o nome
                    final petName = data['petNome']?.toLowerCase() ?? '';
                    final donoName = data['donoNome']?.toLowerCase() ?? '';
                    final nomeFiltroLowerCase = _nomeFiltro.toLowerCase();
                    final nomeMatch = petName.contains(nomeFiltroLowerCase) || donoName.contains(nomeFiltroLowerCase);

                    // Lógica de filtro para a data
                    // NOVO: Verificação para garantir que o campo não é nulo antes de tentar converter
                    final dataConsultaTimestamp = data['dataHoraConsulta'] as Timestamp?;
                    if (dataConsultaTimestamp == null) return false; // Ignora documentos sem data
                    final dataConsulta = dataConsultaTimestamp.toDate();
                    final dataMatch = _dataFiltro == null || isSameDay(dataConsulta, _dataFiltro!);

                    return nomeMatch && dataMatch;
                  }).toList();

                  if (consultas.isEmpty) {
                    return const Center(child: Text('Nenhuma consulta encontrada.'));
                  }

                  return ListView.builder(
                    itemCount: consultas.length,
                    itemBuilder: (context, index) {
                      final consulta = consultas[index].data() as Map<String, dynamic>;
                      
                      final dataHoraTimestamp = consulta['dataHoraConsulta'] as Timestamp?;
                      final dataHora = dataHoraTimestamp?.toDate();
                      final String dataFormatada = dataHora != null ? DateFormat('dd/MM/yyyy HH:mm').format(dataHora) : 'Data não encontrada';
                      
                      final String petNome = consulta['petNome'] ?? 'Pet Desconhecido';
                      final String donoNome = consulta['donoNome'] ?? 'Dono Desconhecido';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Consulta com $petNome'),
                          subtitle: Text('Dono: $donoNome\nData: $dataFormatada'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Ação ao clicar: navegar para os detalhes da consulta
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Função auxiliar para verificar se duas datas são o mesmo dia
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}