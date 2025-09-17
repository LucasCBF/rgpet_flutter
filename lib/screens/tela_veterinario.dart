import 'package:flutter/material.dart';
import 'package:rgpet/screens/perfil_veterinario_screen.dart';
import 'package:rgpet/screens/tela_consultas_veterinario.dart';
import 'package:rgpet/screens/tela_solicitacoes_veterinario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaVeterinario extends StatefulWidget {
  const TelaVeterinario({super.key});

  @override
  State<TelaVeterinario> createState() => _TelaVeterinarioState();
}

class _TelaVeterinarioState extends State<TelaVeterinario> {
  int _selectedIndex = 0; // Para controlar a barra de navegação inferior

  static final List<Widget> _widgetOptions = <Widget>[
    const _VeterinarioHomePageContent(),
    const TelaSolicitacoesVeterinario(),
    const TelaConsultasVeterinario(),
    const PerfilVeterinarioScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

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
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
              }
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C2C3A),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: 'Solicitações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Consultas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
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

// Widget para o conteúdo da Homepage do Veterinário
class _VeterinarioHomePageContent extends StatefulWidget {
  const _VeterinarioHomePageContent({super.key});

  @override
  State<_VeterinarioHomePageContent> createState() => _VeterinarioHomePageContentState();
}

class _VeterinarioHomePageContentState extends State<_VeterinarioHomePageContent> {
  String _nomeVeterinario = 'Veterinário(a)';
  int _unseenNotificationsCount = 0;
  String? _veterinarioId;

  // NOVO: Variável para a contagem de consultas de hoje
  int _consultasHojeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVeterinarioName();
    _setupNotificationListener();
    _setupConsultasHojeListener(); // Configura o listener para consultas de hoje
  }

  Future<void> _loadVeterinarioName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _veterinarioId = user.uid;
        DocumentSnapshot<Map<String, dynamic>> veterinarioDoc = await FirebaseFirestore.instance.collection('veterinarios').doc(user.uid).get();

        if (veterinarioDoc.exists) {
          if (mounted) {
            setState(() {
              _nomeVeterinario = veterinarioDoc.data()?['nomeCompleto'] ?? 'Veterinário(a)';
            });
          }
        }
      } catch (e) {
        print('Erro ao carregar nome do veterinário do Firestore: $e');
      }
    }
  }

  void _setupNotificationListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _veterinarioId = user.uid;
      FirebaseFirestore.instance
          .collection('notificacoesVeterinario')
          .where('veterinarioId', isEqualTo: _veterinarioId)
          .where('lida', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _unseenNotificationsCount = snapshot.docs.length;
          });
        }
      });
    }
  }

  // NOVO: Listener para contar consultas de hoje
  void _setupConsultasHojeListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _veterinarioId = user.uid;

      // Define o início e o fim do dia de hoje (em UTC para compatibilidade com o Firestore)
      final startOfToday = DateTime.now().toUtc().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      FirebaseFirestore.instance
          .collection('consultas')
          .where('veterinarioId', isEqualTo: _veterinarioId)
          .where('dataHoraConsulta', isGreaterThanOrEqualTo: startOfToday)
          .where('dataHoraConsulta', isLessThan: endOfToday)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _consultasHojeCount = snapshot.docs.length;
          });
        }
      });
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
            'Olá, $_nomeVeterinario!',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Text(
            'Visão Geral',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey[800],
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () {
                // Ação ao clicar: navegar para a tela de consultas de hoje
                // Idealmente, passaria a data de hoje como parâmetro para a tela
                // de consultas para que ela já venha filtrada.
                Navigator.of(context).pushNamed(
                  '/consultas', // Assumindo uma rota para a tela de consultas
                  arguments: {'dataFiltro': DateTime.now()}, // Passa a data de hoje
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 30, color: Colors.redAccent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consultas Hoje:',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Você tem $_consultasHojeCount consultas agendadas para hoje.',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white70),
                  ],
                ),
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
                icon: Icons.calendar_month,
                label: 'Gerenciar Agenda',
                onPressed: () {
                  Navigator.of(context).pushNamed('/gerenciar_horarios_veterinario');
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.pets,
                label: 'Meus Pacientes',
                onPressed: () {
                  // Navegação para a tela de pacientes
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.history,
                label: 'Histórico de Procedimentos',
                onPressed: () {
                  Navigator.of(context).pushNamed('/historico_consultas');
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.mail,
                label: 'Mensagens',
                onPressed: () {
                  // Navegação para a tela de mensagens
                },
                badgeCount: _unseenNotificationsCount,
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Alertas e Notificações',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
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
                _buildWarningCard(
                  context,
                  title: 'Atestados Pendentes',
                  subtitle: '5 atestados aguardam sua assinatura.',
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
                _buildWarningCard(
                  context,
                  title: 'Pedidos de Exame',
                  subtitle: '2 novos pedidos de exame para revisão.',
                  icon: Icons.assignment,
                  color: Colors.cyan,
                ),
                _buildWarningCard(
                  context,
                  title: 'Mensagens Não Lidas',
                  subtitle: 'Você tem $_unseenNotificationsCount novas mensagens.',
                  icon: Icons.mail,
                  color: Colors.purple,
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
    required VoidCallback onPressed,
    int? badgeCount,
  }) {
    return Card(
      color: Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, size: 48, color: const Color(0xFFFDC03D)),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        color: color.withOpacity(0.9),
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
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70),
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