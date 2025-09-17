// lib/screens/tela_solicitacoes_veterinario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TelaSolicitacoesVeterinario extends StatefulWidget {
  const TelaSolicitacoesVeterinario({super.key});

  @override
  State<TelaSolicitacoesVeterinario> createState() => _TelaSolicitacoesVeterinarioState();
}

class _TelaSolicitacoesVeterinarioState extends State<TelaSolicitacoesVeterinario> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  Stream<QuerySnapshot>? _solicitacoesStream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _setupSolicitacoesStream();
    }
  }

  void _setupSolicitacoesStream() {
    _solicitacoesStream = _firestore
        .collection('consultas')
        .where('veterinarioId', isEqualTo: _currentUser!.uid)
        .where('status', isEqualTo: 'pendente')
        .orderBy('dataAgendamento', descending: true)
        .snapshots();
  }

  void _showSolicitacaoPopup(BuildContext context, Map<String, dynamic> consultaData, String consultaId) {
    final Timestamp dataHoraTimestamp = consultaData['dataHoraConsulta'];
    final String dataFormatada = DateFormat('dd/MM/yyyy').format(dataHoraTimestamp.toDate());
    final String horaFormatada = DateFormat('HH:mm').format(dataHoraTimestamp.toDate());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3E),
          title: const Text('Solicitação de Consulta', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pet: ${consultaData['petNome']} (Dono: ${consultaData['donoNome']})', style: const TextStyle(color: Colors.white70)),
              Text('Procedimento: ${consultaData['procedimento']}', style: const TextStyle(color: Colors.white)),
              Text('Data: $dataFormatada às $horaFormatada', style: const TextStyle(color: Colors.white70)),
              Text('Motivo: ${consultaData['motivoConsulta']}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmarRejeitarConsulta(consultaId, consultaData['horariosAgendadosIds'], 'rejeitada');
              },
              child: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmarRejeitarConsulta(consultaId, consultaData['horariosAgendadosIds'], 'confirmada');
              },
              child: const Text('Confirmar', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarRejeitarConsulta(String consultaId, List<dynamic> horariosIds, String novoStatus) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      DocumentReference consultaRef = _firestore.collection('consultas').doc(consultaId);
      batch.update(consultaRef, {'status': novoStatus});

      if (novoStatus == 'rejeitada') {
        for (String horarioId in horariosIds.cast<String>()) {
          DocumentReference horarioRef = _firestore.collection('horariosDisponiveis').doc(horarioId);
          batch.update(horarioRef, {
            'isAgendado': false,
            'donoUidAgendamento': null,
            'petIdAgendamento': null,
            'consultaId': null,
          });
        }
      }

      QuerySnapshot notifs = await _firestore.collection('notificacoesVeterinario')
          .where('consultaId', isEqualTo: consultaId)
          .limit(1)
          .get();
      if (notifs.docs.isNotEmpty) {
        DocumentReference notifRef = _firestore.collection('notificacoesVeterinario').doc(notifs.docs.first.id);
        batch.delete(notifRef);
      }
      
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consulta $novoStatus com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar status: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(
        child: Text(
          'Por favor, faça login para ver suas solicitações.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Solicitações de Consulta',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _solicitacoesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar solicitações: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Você não tem novas solicitações de consulta.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var consultaDoc = snapshot.data!.docs[index];
              var consulta = consultaDoc.data() as Map<String, dynamic>;
              String consultaId = consultaDoc.id;

              String petName = consulta['petNome'] ?? 'Pet Desconhecido';
              String donoName = consulta['donoNome'] ?? 'Dono Desconhecido';
              String procedimento = consulta['procedimento'] ?? 'Procedimento não especificado';

              final dataHoraTimestamp = consulta['dataHoraConsulta'] as Timestamp?;
              final String dataHoraFormatada = dataHoraTimestamp != null 
                ? DateFormat('dd/MM/yyyy HH:mm').format(dataHoraTimestamp.toDate()) 
                : 'Data não encontrada';

              return Card(
                color: const Color(0xFF2C2C3A),
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: ListTile(
                  title: Text('Solicitação de $procedimento', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Pet: $petName (Dono: $donoName)\nData: $dataHoraFormatada', style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                  onTap: () => _showSolicitacaoPopup(context, consulta, consultaId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}