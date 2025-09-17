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
    // Lógica de navegação para a tela de Perfil, se o item "Perfil" for tocado
    if (index == 3) { 
      Navigator.of(context).pushNamed('/perfil_veterinario');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Cor de fundo escura
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C), // Cor de fundo escura para a AppBar
        title: Text(
          'RGPet', // Título fixo "RGPet"
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.redAccent, // Título em vermelho
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70), // Ícone branco
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
              }
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex), // Mostra o widget selecionado
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C2C3A), // Fundo mais escuro para a barra de navegação
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail), // Ícone para mensagens/solicitações
            label: 'Solicitações', // Label agora é "Solicitações"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), // Ícone para consultas/agenda
            label: 'Consultas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Usamos person para perfil
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFDC03D), // Amarelo/Laranja do tema
        unselectedItemColor: Colors.white70, // Texto mais claro para não selecionados
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Garante que todos os itens apareçam
      ),
    );
  }
}

// Widget para o conteúdo da Homepage do Veterinário
class _VeterinarioHomePageContent extends StatefulWidget {
  const _VeterinarioHomePageContent(); // Mantenha super.key

  @override
  State<_VeterinarioHomePageContent> createState() => _VeterinarioHomePageContentState();
}

class _VeterinarioHomePageContentState extends State<_VeterinarioHomePageContent> {
  String _nomeVeterinario = 'Veterinário(a)'; // Estado para armazenar o nome
  int _unseenNotificationsCount = 0; // Estado para o contador de notificações
  String? _veterinarioId;

  @override
  void initState() {
    super.initState();
    _loadVeterinarioName(); // Chama a função para carregar o nome
    _setupNotificationListener(); // Configura o listener de notificações
  }

  Future<void> _loadVeterinarioName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> veterinarioDoc =
            await FirebaseFirestore.instance.collection('veterinarios').doc(user.uid).get();

        if (veterinarioDoc.exists) {
          if (mounted) { // Garante que o setState só é chamado se o widget ainda estiver ativo
            setState(() {
              _nomeVeterinario = veterinarioDoc.data()?['nomeCompleto'] ?? 'Veterinário(a)';
            });
          }
        } else {
          print('Documento do veterinário não encontrado no Firestore para UID: ${user.uid}');
        }
      } catch (e) {
        print('Erro ao carregar nome do veterinário do Firestore: $e');
      }
    } else {
      print('Usuário não logado ao tentar carregar nome do veterinário.');
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SAUDAÇÃO PERSONALIZADA (agora na _HomePageContent)
          Text(
            'Olá, $_nomeVeterinario!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16), // Espaço após a saudação

          Text(
            'Visão Geral',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Você tem 3 consultas agendadas para hoje.', // Substituir por contagem dinâmica
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white70),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ver detalhes das consultas de hoje')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          GridView.count(
            crossAxisCount: 2, // 2 colunas
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildActionButton(
                context,
                icon: Icons.calendar_month,
                label: 'Gerenciar Agenda',
                onPressed: () { // MUDANÇA: de onTap para onPressed
                  Navigator.of(context).pushNamed('/gerenciar_horarios_veterinario');
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.pets,
                label: 'Meus Pacientes',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegar para Meus Pacientes')),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.history,
                label: 'Histórico de Consultas',
                onPressed: () {
                  Navigator.of(context).pushNamed('/historico_consultas');
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.mail,
                label: 'Mensagens',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegar para Mensagens')),
                  );
                },
                badgeCount: _unseenNotificationsCount, // Passa o contador de notificações
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Alertas e Notificações',
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
                  subtitle: 'Você tem $_unseenNotificationsCount novas mensagens.', // Atualiza a mensagem com o contador
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
    required VoidCallback onPressed, // MUDANÇA: de onTap para onPressed
    int? badgeCount, // NOVO PARÂMETRO
  }) {
    return Card(
      color: Colors.grey[800], // Fundo escuro como os CustomTextField
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordas arredondadas
      child: InkWell(
        onTap: onPressed, // MUDANÇA: de onTap para onPressed
        borderRadius: BorderRadius.circular(12),
        child: Stack( // Usamos Stack para posicionar o badge
          children: [
            Center( // Centraliza o conteúdo dentro da célula do GridView
              child: SizedBox.expand( // Faz com que o conteúdo preencha o tamanho disponível
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
                    crossAxisAlignment: CrossAxisAlignment.center, // Centraliza horizontalmente o texto
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
            ),
            if (badgeCount != null && badgeCount > 0) // Mostra o badge apenas se houver notificações
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red, // Cor do badge
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
        // Correção: de color.withValues() para color.withOpacity() para não quebrar a funcionalidade
        color: color.withOpacity(0.9), // Usar a cor passada, com um pouco de opacidade
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
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