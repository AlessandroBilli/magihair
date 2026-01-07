import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <--- IMPORTANTE: Questo mancava
import 'package:google_fonts/google_fonts.dart';

import 'features/authentication/services/auth_gate.dart';
import 'utils/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Inizializza la formattazione delle date per l'italiano
  await initializeDateFormatting('it_IT', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magi Hair Off',
      debugShowCheckedModeBanner: false, // Rimuove la scritta "DEBUG" in alto a destra

      // CONFIGURAZIONE TEMA
      theme: ThemeData(
        primaryColor: const Color(0xFF58108E),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF58108E)),
        scaffoldBackgroundColor: const Color(0xFFF8F7FF),
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme).copyWith(
          headlineMedium: GoogleFonts.lora(textStyle: Theme.of(context).textTheme.headlineMedium),
        ),
        useMaterial3: true,
      ),

      // ============================================================
      // CONFIGURAZIONE LOCALIZZAZIONE (Risolve l'errore del DatePicker)
      // ============================================================
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'), // Supportiamo l'italiano
      ],
      // ============================================================

      home: const AuthGate(),
    );
  }
}