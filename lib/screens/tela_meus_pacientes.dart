// lib/screens/tela_meus_pacientes.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Importado para formatar datas, se necessário

class TelaMeusPacientes extends StatefulWidget {
  const TelaMeusPacientes({super.key});

  @override
  State<TelaMeusPacientes> createState() => _TelaMeusPacientesState();
}

class _TelaMeusPacientesState extends State<TelaMeusPacientes> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _veterinarioId;
  String _nomeFiltro = '';
  Stream<QuerySnapshot>? _consultasStream;

  @override
  void initState() {
    super.initState();
    _loadVeterinarioData();
  }

  void _loadVeterinarioData() {
    final user = _auth.currentUser;
    if (user != null) {
      _veterinarioId = user.uid;
      _consultasStream = _firestore
          .collection('consultas')
          .where('veterinarioId', isEqualTo: _veterinarioId)
          .where('status', isEqualTo: 'confirmada')
          .orderBy('dataAgendamento', descending: true)
          .snapshots();
      setState(() {});
    }
  }

  // NOVO: Função para buscar todos os detalhes do pet
  Future<DocumentSnapshot> _fetchFullPetDetails(String donoUid, String petId) async {
    return _firestore
        .collection('donos')
        .doc(donoUid)
        .collection('pets')
        .doc(petId)
        .get();
  }

  // NOVO: Exibe os detalhes do pet em um modal com FutureBuilder
  void _showPetDetailsModal(BuildContext context, Map<String, dynamic> patient) {
    // Obter o ID do Pet e do Dono
    final String petId = patient['petId'];
    final String donoUid = patient['donoUid']; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: _fetchFullPetDetails(donoUid, petId),
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return SizedBox(height: 200, child: Center(child: Text('Erro ao carregar detalhes do pet.', style: Theme.of(context).textTheme.bodyLarge)));
              }

              final petData = snapshot.data!.data() as Map<String, dynamic>;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO DO MODAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalhes do Paciente',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  
                  // NOME DO PET E ÍCONE PARA PRONTUÁRIO
                  Row(
                    children: [
                      Text(
                        patient['petNome'],
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Acessar Prontuário Médico',
                        child: IconButton(
                          icon: const Icon(Icons.description, color: Color(0xFFFDC03D)),
                          onPressed: () {
                            Navigator.pop(context); 
                            Navigator.of(context).pushNamed('/prontuario_pet', arguments: {'petId': petId, 'donoUid': donoUid});
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // TODAS AS INFORMAÇÕES DO PET
                  Text('Dono:', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white70)),
                  Text(patient['donoNome'], style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  Text('Espécie:', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white70)),
                  Text(petData['animal'] ?? 'N/A', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Raça:', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white70)),
                            Text(petData['raca'] ?? 'N/A', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Idade:', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white70)),
                            Text('${petData['idade'] ?? 'N/A'} anos', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text('Peso:', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white70)),
                  Text('${petData['peso']?.toString() ?? 'N/A'} kg', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  Text('Cadastrado em:', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white70)),
                  Text(
                    (petData['dataCadastro'] as Timestamp?) != null 
                        ? DateFormat('dd/MM/yyyy').format((petData['dataCadastro'] as Timestamp).toDate()) 
                        : 'Data não registrada', 
                    style: Theme.of(context).textTheme.titleLarge
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_veterinarioId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meus Pacientes')),
        body: const Center(child: Text('Usuário não logado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pacientes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtro de busca
            TextField(
              onChanged: (value) {
                setState(() {
                  _nomeFiltro = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Filtrar por nome do pet ou do dono',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Lista de pacientes (StreamBuilder)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _consultasStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Nenhum paciente encontrado.'));
                  }

                  // 1. Processar para obter pacientes ÚNICOS e o donoUid
                  final Map<String, Map<String, dynamic>> uniquePatientsMap = {};
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final petId = data['petId'] as String?;
                    
                    if (petId != null) {
                        uniquePatientsMap[petId] = {
                            'petId': petId,
                            'donoUid': data['donoUid'] as String, // AGORA SALVA O DONOUID
                            'petNome': data['petNome'] ?? 'Pet Desconhecido',
                            'donoNome': data['donoNome'] ?? 'Dono Desconhecido',
                        };
                    }
                  }
                  
                  // 2. Converter o mapa de volta para uma lista
                  final List<Map<String, dynamic>> uniquePatients = uniquePatientsMap.values.toList();
                  
                  // 3. Aplicar o filtro de nome localmente
                  final filteredPatients = uniquePatients.where((patient) {
                    final nomeFiltroLowerCase = _nomeFiltro.toLowerCase();
                    final petName = (patient['petNome'] ?? '').toLowerCase(); 
                    final donoName = (patient['donoName'] ?? '').toLowerCase();
                    
                    return petName.contains(nomeFiltroLowerCase) || donoName.contains(nomeFiltroLowerCase);
                  }).toList();


                  if (filteredPatients.isEmpty) {
                    return const Center(child: Text('Nenhum paciente corresponde ao filtro.'));
                  }

                  return ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.pets, color: Colors.blueAccent),
                          title: Text(patient['petNome']),
                          subtitle: Text('Dono: ${patient['donoNome']}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // CHAMA O NOVO MODAL DE DETALHES
                            _showPetDetailsModal(context, patient);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}