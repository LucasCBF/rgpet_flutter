// lib/screens/tela_solicitacoes_veterinario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatar datas

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
    // Ouve as solicitações de consulta (status 'pendente') para este veterinário
    _solicitacoesStream = _firestore
        .collection('consultas')
        .where('veterinarioId', isEqualTo: _currentUser!.uid)
        .where('status', isEqualTo: 'pendente') // Filtra por consultas pendentes
        .orderBy('dataAgendamento', descending: true) // Ordena pelas mais recentes
        .snapshots();
  }

  // Função para buscar o nome do pet e dono
  Future<Map<String, String>> _fetchPetAndDonoNames(String petId, String donoUid) async {
    String petName = 'Pet Desconhecido';
    String donoName = 'Dono Desconhecido';

    try {
      // Busca o nome do pet
      DocumentSnapshot petDoc = await _firestore
          .collection('donos')
          .doc(donoUid)
          .collection('pets')
          .doc(petId)
          .get();

      if (petDoc.exists) {
        petName = (petDoc.data() as Map<String, dynamic>)['nome'] ?? 'Pet sem nome';
      }

      // Busca o nome do dono
      DocumentSnapshot donoDoc = await _firestore
          .collection('donos')
          .doc(donoUid)
          .get();

      if (donoDoc.exists) {
        donoName = (donoDoc.data() as Map<String, dynamic>)['nomeCompleto'] ?? 'Dono sem nome';
      }

    } catch (e) {
      print('Erro ao buscar nome do pet/dono para solicitação: $e');
    }
    return {'petName': petName, 'donoName': donoName};
  }

  // Função para confirmar uma consulta
  Future<void> _confirmarConsulta(String consultaId, String horarioDisponivelId, String donoUid, String petId, String dataConsulta, String horaConsulta) async {
    try {
      await _firestore.collection('consultas').doc(consultaId).update({
        'status': 'confirmado',
      });

      // Notificar o dono (opcional, mas recomendado para o futuro)
      // await _firestore.collection('notificacoesDono').add({
      //   'donoUid': donoUid,
      //   'tipo': 'consulta_confirmada',
      //   'mensagem': 'Sua consulta para $petName em $dataConsulta às $horaConsulta foi confirmada.',
      //   'lida': false,
      //   'timestamp': FieldValue.serverTimestamp(),
      //   'consultaId': consultaId,
      // });

      // Atualiza a notificação do veterinário como lida ou a remove se for específica para aprovação
      QuerySnapshot notifs = await _firestore.collection('notificacoesVeterinario')
          .where('consultaId', isEqualTo: consultaId)
          .limit(1)
          .get();
      if (notifs.docs.isNotEmpty) {
        await _firestore.collection('notificacoesVeterinario').doc(notifs.docs.first.id).update({'lida': true});
        // Ou, se a notificação é só para solicitação, pode-se deletá-la:
        // await _firestore.collection('notificacoesVeterinario').doc(notifs.docs.first.id).delete();
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta confirmada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao confirmar consulta: ${e.toString()}')),
        );
      }
      print('Erro ao confirmar consulta: $e');
    }
  }

  // Função para rejeitar uma consulta
  Future<void> _rejeitarConsulta(String consultaId, String horarioDisponivelId) async {
    try {
      // Altera o status da consulta para 'rejeitada'
      await _firestore.collection('consultas').doc(consultaId).update({
        'status': 'rejeitada',
      });

      // Libera o horário na agenda do veterinário, marcando isAgendado para false novamente
      await _firestore.collection('horariosDisponiveis').doc(horarioDisponivelId).update({
        'isAgendado': false,
        'donoUidAgendamento': null,
        'petIdAgendamento': null,
        'consultaId': null,
      });

      // Atualiza a notificação do veterinário como lida ou a remove
      QuerySnapshot notifs = await _firestore.collection('notificacoesVeterinario')
          .where('consultaId', isEqualTo: consultaId)
          .limit(1)
          .get();
      if (notifs.docs.isNotEmpty) {
        await _firestore.collection('notificacoesVeterinario').doc(notifs.docs.first.id).update({'lida': true});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta rejeitada. Horário liberado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao rejeitar consulta: ${e.toString()}')),
        );
      }
      print('Erro ao rejeitar consulta: $e');
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

              String dataConsulta = consulta['dataConsulta'] ?? 'N/A';
              String horaConsulta = consulta['horaConsulta'] ?? 'N/A';
              String motivoConsulta = consulta['motivoConsulta'] ?? 'Motivo não informado';
              String petId = consulta['petId'] ?? '';
              String donoUid = consulta['donoUid'] ?? '';
              String horarioDisponivelId = consulta['horarioDisponivelId'] ?? '';


              String formattedDate = dataConsulta;
              try {
                formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(dataConsulta));
              } catch (_) {} // Ignora erro de formato se a data não for um DateTime válido

              return FutureBuilder<Map<String, String>>(
                future: _fetchPetAndDonoNames(petId, donoUid),
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: const ListTile(
                        title: Text('Carregando solicitação...', style: TextStyle(color: Colors.white)),
                        trailing: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  String petName = nameSnapshot.data?['petName'] ?? 'Pet';
                  String donoName = nameSnapshot.data?['donoName'] ?? 'Dono';

                  return Card(
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitação de Consulta',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pet: $petName (Dono: $donoName)',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            'Data: $formattedDate às $horaConsulta',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            'Motivo: $motivoConsulta',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _confirmarConsulta(
                                  consultaId,
                                  horarioDisponivelId,
                                  donoUid,
                                  petId,
                                  dataConsulta,
                                  horaConsulta
                                ),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: Text('Confirmar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, // Cor verde para confirmar
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _rejeitarConsulta(
                                  consultaId,
                                  horarioDisponivelId,
                                ),
                                icon: const Icon(Icons.close, color: Colors.white),
                                label: Text('Rejeitar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red, // Cor vermelha para rejeitar
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}