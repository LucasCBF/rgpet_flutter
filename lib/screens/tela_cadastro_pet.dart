import 'package:flutter/material.dart';
import 'package:rgpet/widgets/custom_text_field.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaCadastroPet extends StatefulWidget {
  const TelaCadastroPet({super.key});

  @override
  State<TelaCadastroPet> createState() => _TelaCadastroPetState();
}

class _TelaCadastroPetState extends State<TelaCadastroPet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _racaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _animalController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    _animalController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarPet() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Salva os dados do pet no Firestore, na subcoleção 'pets' do documento do dono
          await FirebaseFirestore.instance.collection('donos').doc(user.uid).collection('pets').add({
            'nome': _nomeController.text.trim(),
            'raca': _racaController.text.trim(),
            'idade': int.tryParse(_idadeController.text.trim()) ?? 0, // Garante que a idade seja um inteiro
            'animal': _animalController.text.trim(), // Salva o tipo de animal
            'peso': double.tryParse(_pesoController.text.trim()) ?? 0.0, // Salva o peso
            'dataCadastro': FieldValue.serverTimestamp(), // Adiciona um timestamp para a data de cadastro
          });

          // Exibe uma mensagem de sucesso
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pet cadastrado com sucesso!')),
            );
            Navigator.of(context).pop(); // Volta para a tela de listagem
          }
        } else {
          // Usuário não está logado (isso não deveria acontecer aqui)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Usuário não logado.')),
            );
          }
        }
      } catch (e) {
        // Trata erros ao salvar no Firestore
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cadastrar pet: ${e.toString()}')),
          );
        }
        print('Erro ao cadastrar pet: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Cadastrar Pet',
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
              CustomTextField(
                controller: _nomeController,
                hintText: 'Nome do Pet',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do pet.';
                  }
                  return null;
                }, labelText: '',
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _racaController,
                hintText: 'Raça',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a raça do pet.';
                  }
                  return null;
                }, labelText: '',
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _idadeController,
                hintText: 'Idade',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a idade do pet.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor, insira um número válido para a idade.';
                  }
                  return null;
                }, labelText: '',
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _animalController,
                hintText: 'Espécie',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o tipo de animal.';
                  }
                  return null;
                }, labelText: '',
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _pesoController,
                hintText: 'Peso (kg)', // Campo Peso
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o peso do pet.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, insira um número válido para o peso.';
                  }
                  return null;
                }, labelText: '',
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Cadastrar',
                backgroundColor: const Color(0xFFFDC03D),
                onPressed: _cadastrarPet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}