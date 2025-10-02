import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaVeterinario extends StatelessWidget {
  const TelaVeterinario({super.key});

  // A tela Veterinario não precisa mais de estado para gerenciar o Bottom Bar.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        // NOVO: ÍCONE DE PERFIL (Canto Superior Esquerdo)
        leading: IconButton(
          icon: const Icon(Icons.person, color: Color(0xFFFDC03D), size: 28), // Ícone de perfil
          onPressed: () {
            // Navega para a tela de Perfil
            Navigator.of(context).pushNamed('/perfil_veterinario');
          },
          tooltip: 'Perfil',
        ),
        title: Text(
          'RGPet',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Retorna para a tela de login
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
      // O body agora exibe o conteúdo da Home diretamente
      body: const _VeterinarioHomePageContent(),
      // REMOVIDO: bottomNavigationBar
    );
  }
}

// Widget para o conteúdo da Homepage do Veterinário
class _VeterinarioHomePageContent extends StatefulWidget {
  const _VeterinarioHomePageContent(); // Adicionando a chave super.key

  @override
  State<_VeterinarioHomePageContent> createState() => _VeterinarioHomePageContentState();
}

class _VeterinarioHomePageContentState extends State<_VeterinarioHomePageContent> {
  String _nomeVeterinario = 'Veterinário(a)';
  int _unseenNotificationsCount = 0;
  String? _veterinarioId;
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

  void _setupConsultasHojeListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _veterinarioId = user.uid;

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
                // Navega para a tela de consultas, aplicando o filtro de data para hoje
                Navigator.of(context).pushNamed(
                  '/consultas',
                  arguments: {'dataFiltro': DateTime.now()},
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
                label: 'Agenda',
                onPressed: () {
                  Navigator.of(context).pushNamed('/gerenciar_horarios_veterinario');
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.pets,
                label: 'Meus Pacientes',
                onPressed: () {
                  Navigator.of(context).pushNamed('/meus_pacientes');
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
                label: 'Caixa de Entrada',
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

  // Helper para construir os botões de ação com estilo customizado
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

  // Helper para construir os cards de aviso
  Widget _buildWarningCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        // CORREÇÃO: Usando withOpacity para garantir que o método seja válido
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