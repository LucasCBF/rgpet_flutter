import 'package:flutter/material.dart';
import 'package:rgpet/widgets/custom_button.dart';

class TelaInicialScreen extends StatelessWidget {
  const TelaInicialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Título "RgPet"
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.redAccent, Colors.orangeAccent], // Gradiente de cores para o texto
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'RgPet',
                  style: TextStyle(
                    fontSize: 64, // Tamanho grande para o título
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // A cor aqui será mascarada pelo shader
                  ),
                ),
              ),
              const SizedBox(height: 80), // Espaço entre o título e os botões

              // Botão "Cadastrar"
              CustomButton(
                text: 'Cadastrar',
                backgroundColor: const Color(0xFFFF4D67),
                onPressed: () {
                  Navigator.pushNamed(context, '/cadastros'); // Navega para a tela de cadastros
                },
              ),
              const SizedBox(height: 20), // Espaço entre os botões

              // Botão "Entrar"
              CustomButton(
                text: 'Entrar',
                backgroundColor: const Color(0xFFFDC03D),
                onPressed: () {
                  Navigator.pushNamed(context, '/login'); // Navega para a tela de login
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
