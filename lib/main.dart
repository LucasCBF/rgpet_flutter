import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importe esta linha
import 'package:intl/date_symbol_data_local.dart'; // Importe esta linha

import 'package:rgpet/screens/cadastros_screen.dart';
import 'package:rgpet/screens/cadastro_dono_screen.dart';
import 'package:rgpet/screens/cadastro_veterinario_screen.dart';
import 'package:rgpet/screens/tela_inicial_screen.dart';
import 'package:rgpet/screens/tela_login_screen.dart';
import 'package:rgpet/screens/tela_dono.dart';
import 'package:rgpet/screens/tela_veterinario.dart';
import 'package:rgpet/screens/tela_cadastro_pet.dart';
import 'package:rgpet/screens/tela_agendamento_dono.dart';
import 'package:rgpet/screens/tela_gerenciar_horarios_veterinario.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicialização do Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Inicialização da formatação de data para o locale pt_BR
  await initializeDateFormatting('pt_BR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Função para determinar a tela inicial com base no tipo de usuário
  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    print('[_getInitialScreen] - Usuário atual: ${user?.email}'); // Adicionar
    if (user == null) {
      print('[_getInitialScreen] - Usuário nulo, retornando TelaInicialScreen.'); // Adicionar
      // Se não há usuário logado, retorna a tela inicial de boas-vindas
      return const TelaInicialScreen(); // Volta para a sua tela inicial
    } else {
      // Se há um usuário logado, tenta buscar o tipo no Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        print('[_getInitialScreen] - Documento do usuário existe: ${userDoc.exists}'); // Adicionar
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userType = userData['tipoUsuario'];
          print('[_getInitialScreen] - Tipo de usuário: $userType'); // Adicionar

          if (userType == 'dono') {
            return const TelaDono();
          } else if (userType == 'veterinario') {
            return const TelaVeterinario();
          }
        }
        // Se o documento não existir ou não tiver o tipo de usuário,
        // pode ser um erro ou um usuário antigo sem o campo.
        // O ideal é deslogar e ir para a tela de login/cadastro para corrigir.
        print('[_getInitialScreen] - Documento não existe ou tipo de usuário inválido. Deslogando.'); // Adicionar
        await FirebaseAuth.instance.signOut();
        return const TelaInicialScreen(); // Ou TelaLoginScreen()
      } catch (e) {
        print('Erro ao buscar tipo de usuário no Firestore: $e');
        await FirebaseAuth.instance.signOut(); // Desloga em caso de erro
        return const TelaInicialScreen(); // Fallback para a tela inicial
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RgPet App',
      // Adicione estas 3 linhas
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Suporte para português do Brasil
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        cardColor: const Color(0xFF2A2A3E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E2C),
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
          labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // NOVO: Use um StreamBuilder para observar o estado de autenticação
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Escuta mudanças no estado de autenticação
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Mostra um indicador de progresso enquanto o Firebase verifica o estado inicial
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          // Se houver um usuário logado (snapshot.hasData é true), determine a tela com base no perfil
          // Se não houver usuário logado (snapshot.hasData é false), vai para a tela inicial
          return FutureBuilder<Widget>(
            future: _getInitialScreen(),
            builder: (context, screenSnapshot) {
              if (screenSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (screenSnapshot.hasData) {
                return screenSnapshot.data!;
              }
              // Fallback caso algo dê errado
              return const TelaInicialScreen();
            },
          );
        },
      ),
      routes: {
        '/cadastros': (context) => const CadastrosScreen(),
        '/cadastro_veterinario': (context) => const CadastroVeterinarioScreen(),
        '/cadastro_dono': (context) => const CadastroDonoScreen(),
        '/cadastro_pet': (context) => const TelaCadastroPet(),
        '/agendar_consulta_dono': (context) => const TelaAgendamentoDono(),
        '/login': (context) => const TelaLoginScreen(),
        '/dono': (context) => const TelaDono(),
        '/veterinario': (context) => const TelaVeterinario(),
        '/gerenciar_horarios_veterinario': (context) => const TelaGerenciarHorariosVeterinario(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}