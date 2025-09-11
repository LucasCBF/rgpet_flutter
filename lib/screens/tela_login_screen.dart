import 'package:flutter/material.dart';
import 'package:rgpet/widgets/custom_button.dart';
import 'package:rgpet/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaLoginScreen extends StatefulWidget {
  const TelaLoginScreen({super.key});

  @override
  State<TelaLoginScreen> createState() => _TelaLoginScreenState();
}

class _TelaLoginScreenState extends State<TelaLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );

        print('Login bem-sucedido para: ${_emailController.text}');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/', // Use a rota raiz nomeada que o MaterialApp gerencia como sua 'home'
            (Route<dynamic> route) => false, // Remove todas as rotas anteriores
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = 'Nenhum usuário encontrado para esse email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Senha incorreta para esse email.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'O formato do email é inválido.';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'Este usuário foi desabilitado.';
        } else {
          errorMessage = 'Erro no login: ${e.message}';
        }
        _showResultDialog('Erro!', errorMessage, isSuccess: false);
        print('Erro de Autenticação Firebase: ${e.code} - ${e.message}');
      } catch (e) {
        _showResultDialog('Erro!', 'Ocorreu um erro inesperado: ${e.toString()}', isSuccess: false);
        print('Erro geral no login: ${e.toString()}');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o email e a senha.')),
      );
    }
  }

  // --- NOVA FUNÇÃO PARA RECUPERAÇÃO DE SENHA ---
  Future<void> _resetPassword() async {
    // 1. Validar se o campo de email não está vazio
    if (_emailController.text.trim().isEmpty) {
      _showResultDialog('Erro', 'Por favor, insira seu email no campo de email para redefinir a senha.', isSuccess: false);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _showResultDialog(
        'E-mail Enviado!',
        'Um e-mail de redefinição de senha foi enviado para ${_emailController.text.trim()}. Por favor, verifique sua caixa de entrada (e spam).',
        isSuccess: true,
      );
      print('Email de redefinição enviado para: ${_emailController.text.trim()}');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'Não há usuário com este email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'O formato do email é inválido.';
      } else {
        errorMessage = 'Erro ao enviar e-mail de redefinição: ${e.message}';
      }
      _showResultDialog('Erro!', errorMessage, isSuccess: false);
      print('Erro Firebase ao redefinir senha: ${e.code} - ${e.message}');
    } catch (e) {
      _showResultDialog('Erro!', 'Ocorreu um erro inesperado ao redefinir a senha: ${e.toString()}', isSuccess: false);
      print('Erro geral ao redefinir senha: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
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
                  controller: _emailController,
                  hintText: 'Email',
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
                  hintText: 'Senha',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  }, labelText: '',
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _resetPassword, // CHAMA A NOVA FUNÇÃO DE REDEFINIÇÃO DE SENHA
                    child: const Text(
                      'ESQUECI MINHA SENHA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: 'ENTRAR',
                  backgroundColor: const Color(0xFFFDC03D),
                  onPressed: _performLogin,
                ),

                const SizedBox(height: 20),
                CustomButton(
                  text: 'CADASTRAR',
                  backgroundColor: const Color(0xFFFF4D67),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cadastros');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}