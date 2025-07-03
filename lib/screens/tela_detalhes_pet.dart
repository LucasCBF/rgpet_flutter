import 'package:flutter/material.dart';

class TelaDetalhesPet extends StatelessWidget {
  final Map<String, dynamic> petData;
  final String petId; // Adicionado para caso precise do ID do documento do pet

  const TelaDetalhesPet({super.key, required this.petData, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          petData['nome'] ?? 'Detalhes do Pet', // Título com o nome do pet
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.pets,
                size: 80,
                color: Theme.of(context).colorScheme.primary, // Cor primária do seu tema
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              label: 'Nome',
              value: petData['nome'] ?? 'N/A',
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              label: 'Espécie',
              value: petData['animal'] ?? 'N/A',
              icon: Icons.category,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              label: 'Raça',
              value: petData['raca'] ?? 'N/A',
              icon: Icons.pets_outlined,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              label: 'Idade',
              value: '${petData['idade'] ?? 'N/A'} anos',
              icon: Icons.cake,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              label: 'Peso',
              value: '${petData['peso'] ?? 'N/A'} kg',
              icon: Icons.scale,
            ),
            const SizedBox(height: 32),
            // TODO: Adicionar mais informações ou botões (ex: Editar Pet, Histórico de Saúde)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Ação para editar o pet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade de edição do pet em desenvolvimento!')),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: Text('Editar Dados do Pet', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({MaterialState.selected}),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String label, required String value, required IconData icon}) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.orangeAccent), // Ícone em destaque
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}