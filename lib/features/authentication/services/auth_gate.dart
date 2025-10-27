import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:magi_hair_off/features/authentication/pages/login_page.dart';
import 'package:magi_hair_off/features/authentication/pages/main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Usiamo uno Scaffold per evitare schermate nere
      body: StreamBuilder<User?>(
        // Questo stream notifica l'app ogni volta che lo stato di login cambia
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Se stiamo ancora verificando lo stato, mostra un caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Se l'utente è loggato (snapshot.hasData è true), mostra la MainScreen
          if (snapshot.hasData) {
            return const MainScreen();
          }

          // Altrimenti, mostra la pagina di login
          return const LoginPage();
        },
      ),
    );
  }
}