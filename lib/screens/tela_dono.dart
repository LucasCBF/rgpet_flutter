import 'package:flutter/material.dart';
import 'package:rgpet/screens/perfil_dono_screen.dart';
import 'package:rgpet/screens/tela_meus_pets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaDono extends StatefulWidget {
  const TelaDono({super.key});

  @override
  State<TelaDono> createState() => _TelaDonoState();
}

class _TelaDonoState extends State<TelaDono> {
  int _selectedIndex = 0; // Para controlar a barra de navegação inferior

  static final List<Widget> _widgetOptions = <Widget>[
    _HomePageContent(),
    const Center(
      child: Text(
        'Tela de Agenda',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    ),
    const TelaMeusPets(),
    const PerfilDonoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(
          'RGPet',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout, color: Colors.white70),
        //     onPressed: () async {
        //       await FirebaseAuth.instance.signOut();
        //       Navigator.of(
        //         context,
        //       ).pushNamedAndRemoveUntil('/login', (route) => false);
        //     },
        //   ),
        // ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C2C3A),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFDC03D),
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Widget para o conteúdo da Homepage com a nova identidade visual
class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  String _nomeDono = 'Dono'; // Estado para armazenar o nome

  @override
  void initState() {
    super.initState();
    _loadDonoName(); // Chama a função para carregar o nome
  }

  Future<void> _loadDonoName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> donoDoc = await FirebaseFirestore
            .instance
            .collection('donos')
            .doc(user.uid)
            .get();

        if (donoDoc.exists) {
          setState(() {
            _nomeDono =
                donoDoc.data()?['nomeCompleto'] ??
                'Dono'; // Pega o nomeCompleto
          });
        } else {
          print(
            'Documento do dono não encontrado no Firestore para UID: ${user.uid}',
          );
        }
      } catch (e) {
        print('Erro ao carregar nome do dono do Firestore: $e');
      }
    } else {
      print('Usuário não logado ao tentar carregar nome do dono.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $_nomeDono!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você tem 4 pets cadastrados.', // Substituir por contagem dinâmica
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey[800],
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 30, color: Colors.redAccent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próxima Consulta:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buddy em 25/07/2025 às 10:00', // Substituir por dados reais
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ver detalhes da consulta'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildActionButton(
                context,
                icon: Icons.add_circle_outline,
                label: 'Cadastrar Novo Pet',
                onTap: () {
                  Navigator.of(context).pushNamed('/cadastro_pet');
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.calendar_today,
                label: 'Agendar Consulta',
                onTap: () {
                  // Ação para navegar para a tela de Agendamento
                  // Agora usa a rota nomeada
                  Navigator.of(context).pushNamed('/agendar_consulta_dono');
                },
              ),
              // _buildActionButton(
              //   context,
              //   icon: Icons.pets,
              //   label: 'Meus Pets',
              //   onTap: () {
              //     Navigator.of(context).push(
              //       MaterialPageRoute(
              //         builder: (context) => const Placeholder(
              //           child: Center(
              //             child: Text(
              //               'Tela de Meus Pets',
              //               style: TextStyle(color: Colors.white, fontSize: 24),
              //             ),
              //           ),
              //         ),
              //       ),
              //     );
              //   },
              // ),
              _buildActionButton(
                context,
                icon: Icons.history,
                label: 'Histórico de Consultas',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Placeholder(
                        child: Center(
                          child: Text(
                            'Tela de Histórico de Consultas',
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.medical_services,
                label: 'Histórico do Pet',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Placeholder(
                        child: Center(
                          child: Text(
                            'Tela de Seleção de Pet para Histórico',
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Dicas para o seu Pet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTipCard(
                  context,
                  title: 'Cuidado com a alimentação',
                  subtitle: 'Mantenha uma dieta balanceada para seu amigo.',
                  icon: Icons.fastfood,
                  color: const Color(0xFFFDC03D),
                ),
                _buildTipCard(
                  context,
                  title: 'Vacinação em dia',
                  subtitle: 'Verifique o calendário de vacinas do seu pet.',
                  icon: Icons.vaccines,
                  color: Colors.redAccent,
                ),
                _buildTipCard(
                  context,
                  title: 'Passeios regulares',
                  subtitle: 'Exercícios são essenciais para a saúde dele.',
                  icon: Icons.sports_handball,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFFFDC03D)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        color: color.withValues(),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
