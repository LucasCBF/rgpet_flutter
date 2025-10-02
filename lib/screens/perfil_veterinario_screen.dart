import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilVeterinarioScreen extends StatefulWidget {
  const PerfilVeterinarioScreen({super.key});

  @override
  State<PerfilVeterinarioScreen> createState() => _PerfilVeterinarioScreenState();
}

class _PerfilVeterinarioScreenState extends State<PerfilVeterinarioScreen> {
  Map<String, dynamic>? _veterinarioData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVeterinarioProfile();
  }

  Future<void> _loadVeterinarioProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Nenhum usuário logado.';
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance.collection('veterinarios').doc(user.uid).get();

      if (docSnapshot.exists) {
        setState(() {
          _veterinarioData = docSnapshot.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Dados do perfil do veterinário não encontrados.';
          _isLoading = false;
        });
        print('Documento do veterinário não encontrado no Firestore para UID: ${user.uid}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar perfil: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao carregar perfil do veterinário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar( // Adicionando AppBar aqui para consistência
        title: Text(
          'Meu Perfil',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _veterinarioData == null
                  ? Center(
                      child: Text(
                        'Nenhum dado de perfil disponível.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome Completo
                          _buildProfileInfoTile(
                            context,
                            icon: Icons.person,
                            label: 'Nome Completo',
                            value: _veterinarioData!['nomeCompleto'] ?? 'N/A',
                          ),
                          const SizedBox(height: 16),
                          // CRMV
                          _buildProfileInfoTile(
                            context,
                            icon: Icons.badge,
                            label: 'CRMV',
                            value: _veterinarioData!['crmv'] ?? 'N/A',
                          ),
                          const SizedBox(height: 16),
                          // Especialização
                          _buildProfileInfoTile(
                            context,
                            icon: Icons.local_hospital,
                            label: 'Especialização',
                            value: _veterinarioData!['especializacao'] ?? 'N/A',
                          ),
                          const SizedBox(height: 16),
                          // Telefone
                          _buildProfileInfoTile(
                            context,
                            icon: Icons.phone,
                            label: 'Telefone',
                            value: _veterinarioData!['telefone'] ?? 'N/A',
                          ),
                          const SizedBox(height: 16),
                          // Email
                          _buildProfileInfoTile(
                            context,
                            icon: Icons.email,
                            label: 'Email',
                            value: _veterinarioData!['email'] ?? 'N/A',
                          ),
                          const SizedBox(height: 16),
                          // Data de Cadastro
                          _buildProfileInfoTile(
                            context,
                            icon: Icons.date_range,
                            label: 'Membro desde',
                            value: (_veterinarioData!['dataCadastro'] as Timestamp?)?.toDate().toLocal().toString().split(' ')[0] ?? 'N/A',
                          ),
                          const SizedBox(height: 32),
                          // Botão para editar perfil
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento!')),
                                );
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: Text('Editar Perfil', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({WidgetState.selected}),
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // Espaço entre os botões
                          // --- NOVO BOTÃO: SAIR DA CONTA ---
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                // Navega para a tela de login e remove todas as rotas anteriores da pilha
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              },
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: Text('Sair da Conta', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700], // Uma cor diferente para logout, por exemplo
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32), // Espaço no final
                        ],
                      ),
                    ),
    );
  }

  // Helper para construir um tile de informação do perfil
  Widget _buildProfileInfoTile(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }
}