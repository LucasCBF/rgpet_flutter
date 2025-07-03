import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:rgpet/screens/tela_detalhes_pet.dart';

class TelaMeusPets extends StatefulWidget {
  const TelaMeusPets({super.key});

  @override
  State<TelaMeusPets> createState() => _TelaMeusPetsState();
}

class _TelaMeusPetsState extends State<TelaMeusPets> {
  User? _currentUser;
  Stream<QuerySnapshot>? _petsStream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _petsStream = FirebaseFirestore.instance
          .collection('donos')
          .doc(_currentUser!.uid)
          .collection('pets')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(
        child: Text(
          'Por favor, faça login para ver seus pets.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Meus Pets',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _petsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar pets: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Você ainda não tem nenhum pet cadastrado.',
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

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var petDoc = snapshot.data!.docs[index]; // Objeto DocumentSnapshot
              var pet = petDoc.data() as Map<String, dynamic>;
              var petId = petDoc.id; // Obtenha o ID do documento do pet

              return Card(
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: ListTile(
                  leading: const Icon(Icons.pets, color: Colors.orangeAccent, size: 40),
                  title: Text(
                    pet['nome'] ?? 'Pet sem nome', // Apenas o nome
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  trailing: IconButton( // Botão para ver detalhes
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                    onPressed: () {
                      // NAVEGA PARA A TELA DE DETALHES, PASSANDO OS DADOS COMPLETOS DO PET
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TelaDetalhesPet(
                            petData: pet, // Passa todos os dados do pet
                            petId: petId, // Passa o ID do documento do pet
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}