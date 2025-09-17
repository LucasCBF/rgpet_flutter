// lib/screens/tela_consultas_veterinario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    // A consulta agora usa o campo 'dataHoraConsulta' para ordenação
    _consultasStream = _firestore
        .collection('consultas')
        .where('veterinarioId', isEqualTo: _currentUser!.uid)
        .where('status', isEqualTo: 'confirmada')
        .orderBy('dataHoraConsulta', descending: false) // CORREÇÃO: Ordena pelo campo Timestamp
        .snapshots();
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
          'Procedimentos Confirmados',
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
              
              // Lendo os nomes e o timestamp diretamente do documento
              String petName = consulta['petNome'] ?? 'Pet Desconhecido';
              String donoName = consulta['donoNome'] ?? 'Dono Desconhecido';
              String procedimento = consulta['procedimento'] ?? 'Procedimento não especificado';
              
              final dataHoraTimestamp = consulta['dataHoraConsulta'] as Timestamp?;
              final dataHora = dataHoraTimestamp?.toDate();
              final String dataFormatada = dataHora != null ? DateFormat('dd/MM/yyyy HH:mm').format(dataHora) : 'Data não encontrada';

              return Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: ListTile(
                  title: Text(
                    procedimento,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Pet: $petName\nDono: $donoName\nData: $dataFormatada',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                  onTap: () {
                    // TODO: Navegar para a tela de detalhes da consulta
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ver detalhes da consulta de ${petName}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}