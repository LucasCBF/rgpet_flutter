import 'package:flutter/material.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:rgpet/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Cloud Firestore

class CadastroDonoScreen extends StatefulWidget {
  const CadastroDonoScreen({super.key});

  @override
  State<CadastroDonoScreen> createState() => _CadastroDonoScreenState();
}

class _CadastroDonoScreenState extends State<CadastroDonoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Função para mostrar um diálogo de erro ou sucesso
  void _showResultDialog(String title, String content, {bool isSuccess = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(title, style: TextStyle(color: isSuccess ? Colors.white : Colors.redAccent)),
          content: Text(content, style: const TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: isSuccess ? Colors.redAccent : Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo

                // ************************************************************
                // ALTERAÇÃO AQUI: Redirecionar para a tela de login se for sucesso
                if (isSuccess) {
                  // Limpar os campos do formulário antes de navegar
                  _nomeController.clear();
                  _cpfController.clear();
                  _enderecoController.clear();
                  _telefoneController.clear();
                  _emailController.clear();
                  _senhaController.clear();

                  // Navega para a tela de login e remove todas as rotas anteriores da pilha
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  // OU, se você quiser apenas voltar para a tela anterior (que pode ser a de login)
                  // Navigator.of(context).pop(); // Volta para a tela anterior
                }
                // ************************************************************
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cadastrarDono() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Criar usuário no Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );

        // Obter o UID do usuário recém-criado
        String uid = userCredential.user!.uid;

        //Salvar dados adicionais ESPECÍFICOS do dono na coleção 'donos'
        await FirebaseFirestore.instance.collection('donos').doc(uid).set({
          'nomeCompleto': _nomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'endereco': _enderecoController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'email': _emailController.text.trim(),
          'dataCadastro': FieldValue.serverTimestamp(),
          'uid': uid,
        });

        //Salvar o tipo de usuário na coleção UNIFICADA 'users'
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'tipoUsuario': 'dono', // Define explicitamente como 'dono'
          'email': _emailController.text.trim(), // Pode adicionar outros dados unificados se quiser
          'uid': uid,
        });

        _showResultDialog('Sucesso!', 'Cadastro de dono realizado com sucesso!');

      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'weak-password') {
          errorMessage = 'A senha fornecida é muito fraca.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Uma conta já existe para esse email.';
        } else {
          errorMessage = 'Ocorreu um erro na autenticação: ${e.message}';
        }
        _showResultDialog('Erro!', errorMessage, isSuccess: false);
        print('Erro de Autenticação Firebase: ${e.code} - ${e.message}');
      } catch (e) {
        _showResultDialog('Erro!', 'Ocorreu um erro ao cadastrar o dono: ${e.toString()}', isSuccess: false);
        print('Erro geral ao cadastrar dono: ${e.toString()}');
      }
    } else {
      // Se o formulário não for válido, os erros serão exibidos ao lado dos campos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios corretamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cadastro Dono',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent, // Título em vermelho
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nomeController,
                  hintText: 'NOME COMPLETO',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome completo';
                    }
                    return null;
                  }, labelText: '',
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _cpfController,
                  hintText: 'CPF',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu CPF';
                    }
                    // Validação básica de comprimento para CPF (11 dígitos numéricos)
                    final String numericValue = value.replaceAll(RegExp(r'\D'), '');
                    if (numericValue.length != 11) {
                      return 'O CPF deve ter 11 dígitos';
                    }
                    return null;
                  }, labelText: '',
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _enderecoController,
                  hintText: 'ENDEREÇO',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu endereço';
                    }
                    return null;
                  }, labelText: '',
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _telefoneController,
                  hintText: 'TELEFONE (DD + Número)',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu telefone';
                    }
                    final String numericValue = value.replaceAll(RegExp(r'\D'), '');
                    if (numericValue.length < 10 || numericValue.length > 11) { // Aceita 10 ou 11 dígitos
                      return 'O telefone deve ter 10 ou 11 dígitos (DDD + Número)';
                    }
                    return null;
                  }, labelText: '',
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'EMAIL',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  }, labelText: '',
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _senhaController,
                  hintText: 'SENHA',
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  }, labelText: '',
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: 'CADASTRAR',
                  backgroundColor: const Color(0xFFFF4D67),
                  onPressed: _cadastrarDono, // Chama a nova função assíncrona
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}