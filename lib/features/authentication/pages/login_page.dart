import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🟢 MODIFICA: Due controller separati invece di uno
  final TextEditingController _firstNameController = TextEditingController(); // Nome
  final TextEditingController _lastNameController = TextEditingController();  // Cognome

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _submit() async {
    String? errorMessage;

    // Controllo campi vuoti
    if (_phoneController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      errorMessage = 'Numero di telefono e password non possono essere vuote.';
    } else if (!_isLogin) {
      // 🟢 MODIFICA: Controllo che sia Nome che Cognome siano compilati
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        errorMessage = 'Nome e Cognome sono obbligatori per la registrazione.';
      }
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      if (_isLogin) {
        await _authService.signInWithPhonePassword(
            _phoneController.text.trim(), _passwordController.text.trim());
      } else {
        // 🟢 MODIFICA: Unisco Nome e Cognome per inviarli al database come unica stringa
        // in modo da non dover modificare il resto dell'app o il modello utente.
        String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

        await _authService.signUpWithPhone(
          _phoneController.text.trim(),
          _passwordController.text.trim(),
          fullName, // Passo il nome completo combinato
        );
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found': errorMessage = 'Nessun utente trovato con questo numero.'; break;
        case 'invalid-phone-number': errorMessage = 'Il numero di telefono non è valido.'; break;
        case 'wrong-password': errorMessage = 'La password non è corretta.'; break;
        default: errorMessage = 'Si è verificato un errore inatteso. Riprova.';
      }
    } catch (e) {
      errorMessage = 'Si è verificato un errore: ${e.toString()}';
    }

    if (mounted) setState(() => _isLoading = false);
    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration( /* ... gradiente ... */ ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // =========================================================
                // HEADER E LOGO
                // =========================================================
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 3,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/img/Logooffmagi.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Magi Hair',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 60),

                // =========================================================
                // CARD DEL MODULO
                // =========================================================
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'Accedi al tuo account' : 'Crea il tuo account',
                          textAlign: TextAlign.left,
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 🟢 CAMPI NOME E COGNOME (Solo in Registrazione)
                        if (!_isLogin) ...[
                          // CAMPO NOME
                          TextField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              hintText: 'Nome', // Modificato
                              hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.person, color: primaryColor.withOpacity(0.7)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words, // Utile per i nomi
                            style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 16),

                          // CAMPO COGNOME
                          TextField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              hintText: 'Cognome', // Modificato
                              hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.person_outline, color: primaryColor.withOpacity(0.7)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words, // Utile per i cognomi
                            style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // CAMPO NUMERO DI TELEFONO
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: 'Numero di telefono',
                            hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            prefixIcon: Icon(Icons.phone_android, color: primaryColor.withOpacity(0.7)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                          keyboardType: TextInputType.phone,
                          style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 16),

                        // CAMPO PASSWORD
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Inserisci password',
                            hintStyle: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            prefixIcon: Icon(Icons.lock_outline, color: primaryColor.withOpacity(0.7)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 30),

                        // PULSANTE SUBMIT
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 6,
                              textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : Text(_isLogin ? 'Accedi' : 'Crea Account'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Link per cambiare modalità (Login/Registrazione)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? 'Non hai un account?' : 'Hai già un account?',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin ? 'Registrati' : 'Accedi',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: primaryColor,
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}