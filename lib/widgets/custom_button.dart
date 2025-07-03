// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final Color textColor;
  final double width; // Adiciona um parâmetro para largura

  const CustomButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.onPressed,
    this.textColor = Colors.white,
    this.width = double.infinity, // Valor padrão para largura total
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // Aplica a largura definida
      height: 50, // Altura fixa para os botões
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor, // Cor de fundo do botão
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0), // Bordas arredondadas
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor),
          elevation: 5, // Sombra para o botão
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor), // Define a cor do texto
        ),
      ),
    );
  }
}
