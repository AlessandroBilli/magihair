import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/authentication/services/auth_gate.dart';
import 'features/authentication/services/auth_service.dart';
import 'features/authentication/pages/home_page.dart';
import 'utils/CreaPrenotazioni.dart';
import 'utils/ListaPrenotazioni.dart';
import 'utils/AdminDashBoardPage.dart';
import 'core/models.dart';
import 'utils/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('it_IT', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magi Hair Off',
      theme: ThemeData(
        primaryColor: const Color(0xFF482069),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF482069)),
        scaffoldBackgroundColor: const Color(0xFFF8F7FF),
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme).copyWith(
          headlineMedium: GoogleFonts.lora(textStyle: Theme.of(context).textTheme.headlineMedium),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}