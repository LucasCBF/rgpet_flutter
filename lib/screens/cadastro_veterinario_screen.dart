import 'package:flutter/material.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:rgpet/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroVeterinarioScreen extends StatefulWidget {
  const CadastroVeterinarioScreen({super.key});

  @override
  State<CadastroVeterinarioScreen> createState() => _CadastroVeterinarioScreenState();
}

class _CadastroVeterinarioScreenState extends State<CadastroVeterinarioScreen> {
  // Chave global para o formulário, que nos permite validar todos os campos de uma vez
  final _formKey = GlobalKey<FormState>();

  // Controladores para pegar o texto dos campos
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _crmvController = TextEditingController();
  final TextEditingController _especializacaoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    // É importante descartar os controladores quando o widget não for mais necessário
    _nomeController.dispose();
    _crmvController.dispose();
    _especializacaoController.dispose();
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
                  _crmvController.clear();
                  _especializacaoController.clear();
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

  Future<void> _cadastrarVeterinario() async {
    if (_formKey.currentState!.validate()) {
      try {
        //Criar usuário no Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );

        // Obter o UID do usuário recém-criado
        String uid = userCredential.user!.uid;

        //Salvar dados adicionais ESPECÍFICOS do veterinário na coleção 'veterinarios'
        await FirebaseFirestore.instance.collection('veterinarios').doc(uid).set({
          'nomeCompleto': _nomeController.text.trim(),
          'crmv': _crmvController.text.trim(),
          'especializacao': _especializacaoController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'email': _emailController.text.trim(),
          'dataCadastro': FieldValue.serverTimestamp(),
          'uid': uid,
        });

        //Salvar o tipo de usuário na coleção UNIFICADA 'users'
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'tipoUsuario': 'veterinario', // Define explicitamente como 'veterinario'
          'email': _emailController.text.trim(), // Pode adicionar outros dados unificados se quiser
          'uid': uid,
        });

        _showResultDialog('Sucesso!', 'Cadastro de veterinário realizado com sucesso!');

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
        _showResultDialog('Erro!', 'Ocorreu um erro ao cadastrar o veterinário: ${e.toString()}', isSuccess: false);
        print('Erro geral ao cadastrar veterinário: ${e.toString()}');
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
          'Cadastro Veterinário',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent, // Título em vermelho
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView( // Permite rolagem se o conteúdo for muito grande
          padding: const EdgeInsets.all(24.0),
          child: Form( // Envolvemos a coluna com um Form para habilitar a validação
            key: _formKey, // Atribuímos a chave global ao Form
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estica os elementos horizontalmente
              children: [
                CustomTextField(
                  controller: _nomeController,
                  hintText: 'NOME COMPLETO',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome completo do veterinário';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _crmvController,
                  hintText: 'CRMV',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o CRMV';
                    }
                    // Adicione validação de formato de CRMV se necessário
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _especializacaoController,
                  hintText: 'ESPECIALIZAÇÃO',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a especialização';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _telefoneController,
                  hintText: 'TELEFONE (DD + Número)',
                  keyboardType: TextInputType.phone, // Mantém o teclado numérico
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o telefone';
                    }
                    // Remove todos os caracteres não numéricos para a validação
                    final String numericValue = value.replaceAll(RegExp(r'\D'), '');
                    if (numericValue.length < 10 || numericValue.length > 11) { // Aceita 10 ou 11 dígitos
                      return 'O telefone deve ter 10 ou 11 dígitos (DDD + Número)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'EMAIL',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _senhaController,
                  hintText: 'SENHA',
                  obscureText: true, // Oculta o texto digitado por segurança
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Botão para finalizar o cadastro
                CustomButton(
                  text: 'CADASTRAR',
                  backgroundColor: const Color(0xFFFF4D67), // Cor vermelha para o botão
                  onPressed: _cadastrarVeterinario, // Chama a nova função assíncrona
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}