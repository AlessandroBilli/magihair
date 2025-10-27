import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();
    String? errorMessage;
    try {
      if (_isLogin) {
        await _authService.signInWithEmailPassword(_emailController.text.trim(), _passwordController.text.trim());
      } else {
        await _authService.signUpWithEmailPassword(_emailController.text.trim(), _passwordController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email': errorMessage = 'L\'indirizzo email non è valido.'; break;
        case 'wrong-password': errorMessage = 'La password non è corretta.'; break;
        case 'user-not-found': errorMessage = 'Nessun utente trovato con questa email.'; break;
        case 'email-already-in-use': errorMessage = 'Questa email è già stata registrata.'; break;
        case 'weak-password': errorMessage = 'La password deve essere di almeno 6 caratteri.'; break;
        default: errorMessage = 'Si è verificato un errore inatteso. Riprova.';
      }
    }
    if (mounted) setState(() => _isLoading = false);
    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usiamo i colori definiti in main.dart tramite Theme.of(context)
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color; // Prende il colore del testo di base

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente il contenuto
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Text(
                _isLogin ? 'Login' : 'Registrazione',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium, // Usa il font Lora dal tema
              ),
              const SizedBox(height: 50),

              // Campo di testo per l'Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.email_outlined, color: primaryColor.withOpacity(0.7)), // Icona
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 16),

              // Campo di testo per la Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.lock_outline, color: primaryColor.withOpacity(0.7)), // Icona
                ),
                obscureText: true,
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 24),

              // Pulsante di invio o indicatore di caricamento
              if (_isLoading)
                Center(child: CircularProgressIndicator(color: primaryColor))
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Accedi' : 'Crea Account'), // Lo stile viene dal tema
                ),
              const SizedBox(height: 40),

              // Link per cambiare modalità (Login/Registrazione)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Non hai un account?' : 'Hai già un account?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor?.withOpacity(0.7)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Registrati' : 'Accedi',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: primaryColor, // Usa il colore primario
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
