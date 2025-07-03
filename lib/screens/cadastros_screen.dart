import 'package:flutter/material.dart';
import 'package:rgpet/widgets/custom_button.dart';

class CadastrosScreen extends StatelessWidget {
  const CadastrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cadastros',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botão "DONO"
              CustomButton(
                text: 'DONO',
                backgroundColor: const Color(0xFFFF4D67),
                onPressed: () {
                  Navigator.pushNamed(context, '/cadastro_dono'); // Navega para cadastro de dono
                },
              ),
              const SizedBox(height: 20), // Espaço entre os botões

              // Botão "VETERINÁRIO"
              CustomButton(
                text: 'VETERINÁRIO',
                backgroundColor: const Color(0xFFFDC03D),
                onPressed: () {
                  Navigator.pushNamed(context, '/cadastro_veterinario'); // Navega para cadastro de veterinário
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
