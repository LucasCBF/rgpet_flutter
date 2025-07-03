// lib/screens/tela_consultas_veterinario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatar datas

class TelaConsultasVeterinario extends StatefulWidget {
  const TelaConsultasVeterinario({super.key});

  @override
  State<TelaConsultasVeterinario> createState() => _TelaConsultasVeterinarioState();
}

class _TelaConsultasVeterinarioState extends State<TelaConsultasVeterinario> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  Stream<QuerySnapshot>? _consultasStream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _setupConsultasStream();
    }
  }

  void _setupConsultasStream() {
    // Ouve as consultas confirmadas para este veterinário
    _consultasStream = _firestore
        .collection('consultas')
        .where('veterinarioId', isEqualTo: _currentUser!.uid)
        .where('status', isEqualTo: 'confirmado') // Filtra por consultas confirmadas
        .orderBy('dataConsulta') // Ordena por data
        .orderBy('horaConsulta') // E depois por hora
        .snapshots();
  }

  // Função para buscar o nome do pet (e do dono, se necessário)
  Future<Map<String, String>> _fetchPetAndDonoNames(String petId, String donoUid) async {
    String petName = 'Nome desconhecido';
    String donoName = 'Dono desconhecido';

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
      print('Erro ao buscar nome do pet/dono: $e');
    }
    return {'petName': petName, 'donoName': donoName};
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(
        child: Text(
          'Por favor, faça login para ver suas consultas.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Consultas Confirmadas',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _consultasStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar consultas: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Você não tem consultas confirmadas no momento.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var consulta = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String dataConsulta = consulta['dataConsulta'] ?? 'N/A';
              String horaConsulta = consulta['horaConsulta'] ?? 'N/A';
              String petId = consulta['petId'] ?? '';
              String donoUid = consulta['donoUid'] ?? '';

              // Formata a data para exibição
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
                        title: Text('Carregando consulta...', style: TextStyle(color: Colors.white)),
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
                    child: ListTile(
                      leading: const Icon(Icons.pets, color: Colors.blueAccent, size: 40),
                      title: Text(
                        '${petName} (${donoName})', // Nome do Pet (Nome do Dono)
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        '$formattedDate às $horaConsulta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                        onPressed: () {
                          // TODO: Navegar para a tela de detalhes da consulta
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ver detalhes da consulta de ${petName}')),
                          );
                        },
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