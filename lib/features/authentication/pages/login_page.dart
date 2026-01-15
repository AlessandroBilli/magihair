import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'terms_page.dart';
import 'package:url_launcher/url_launcher.dart'; // Necessario per la chiamata

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Stati
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptedTerms = false;

  // Funzione per effettuare la chiamata al salone
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile effettuare la chiamata')),
        );
      }
    }
  }

  void _submit() async {
    String? errorMessage;
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validazione Campi Vuoti Generici
    if (_phoneController.text.trim().isEmpty || password.isEmpty) {
      errorMessage = 'Numero di telefono e password sono obbligatori.';
    }
    // 2. Validazione Specifica per Registrazione
    else if (!_isLogin) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        errorMessage = 'Nome e Cognome sono obbligatori per la registrazione.';
      }
      // Validazione Password
      else if (password.length < 6) {
        errorMessage = 'La password deve contenere almeno 6 caratteri.';
      } else if (password != confirmPassword) {
        errorMessage = 'Le password inserite non coincidono.';
      }
      // Validazione Privacy
      else if (!_acceptedTerms) {
        errorMessage = 'Devi accettare i termini e la privacy per registrarti.';
      }
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      if (_isLogin) {
        // LOGIN
        await _authService.signInWithPhonePassword(
            _phoneController.text.trim(), password);
      } else {
        // REGISTRAZIONE
        String fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
        await _authService.signUpWithPhone(
          _phoneController.text.trim(),
          password,
          fullName,
        );
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found': errorMessage = 'Nessun utente trovato con questo numero.'; break;
        case 'invalid-phone-number': errorMessage = 'Il numero di telefono non è valido.'; break;
        case 'wrong-password': errorMessage = 'La password non è corretta.'; break;
        case 'email-already-in-use': errorMessage = 'Il numero risulta già registrato.'; break;
        case 'weak-password': errorMessage = 'La password è troppo debole.'; break;
        default: errorMessage = 'Errore: ${e.message}';
      }
    } catch (e) {
      errorMessage = 'Si è verificato un errore: ${e.toString()}';
    }

    if (mounted) setState(() => _isLoading = false);
    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    // Il pulsante è attivo se: È Login OPPURE (È Registrazione E Termini Accettati)
    final bool isButtonEnabled = _isLogin || (!_isLogin && _acceptedTerms);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
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
                            offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Image.asset('assets/img/Logooffmagi.png', height: 80, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Magi Hair',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge?.copyWith(
                        color: primaryColor, fontWeight: FontWeight.w900)),
                const SizedBox(height: 40),

                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'Accedi al tuo account' : 'Crea il tuo account',
                          textAlign: TextAlign.left,
                          style: textTheme.headlineSmall?.copyWith(
                              color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 25),

                        // Campi Nome e Cognome (Solo Registrazione)
                        if (!_isLogin) ...[
                          TextField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              hintText: 'Nome',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              prefixIcon: Icon(Icons.person, color: primaryColor.withOpacity(0.7)),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              hintText: 'Cognome',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              prefixIcon: Icon(Icons.person_outline, color: primaryColor.withOpacity(0.7)),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Campo Telefono
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: 'Numero di telefono',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            prefixIcon: Icon(Icons.phone_android, color: primaryColor.withOpacity(0.7)),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Campo Password Principale
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Inserisci password',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            prefixIcon: Icon(Icons.lock_outline, color: primaryColor.withOpacity(0.7)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey.shade500),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                        ),

                        // 🟢 TASTO PASSWORD DIMENTICATA (Solo Login)
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text("Password dimenticata?",
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                    content: const Text(
                                      "Per motivi di sicurezza, il recupero della password deve essere gestito dal salone.\n\n"
                                          "Contattaci telefonicamente: verificheremo la tua identità e ti aiuteremo a ripristinare l'accesso.",
                                      style: TextStyle(height: 1.5),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Chiudi", style: TextStyle(color: Colors.grey)),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _makePhoneCall('+393888106944'); // Numero del salone
                                        },
                                        icon: const Icon(Icons.call, size: 18, color: Colors.white),
                                        label: const Text("Chiama Salone", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                "Password dimenticata?",
                                style: TextStyle(
                                    color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),

                        // Requisiti Password (Solo Registrazione)
                        if (!_isLogin)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                            child: Text(
                              "La password deve contenere almeno 6 caratteri.",
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),

                        // Conferma Password (Solo Registrazione)
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: 'Conferma password',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              prefixIcon: Icon(Icons.lock_reset, color: primaryColor.withOpacity(0.7)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey.shade500),
                                onPressed: () => setState(
                                        () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                              ),
                            ),
                            obscureText: !_isConfirmPasswordVisible,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Checkbox Privacy (Solo Registrazione)
                        if (!_isLogin) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  activeColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() {
                                      _acceptedTerms = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const TermsPage()),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      children: [
                                        const TextSpan(text: "Ho letto e accetto la "),
                                        TextSpan(
                                          text: "Privacy Policy",
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                        ],

                        // Pulsante Login/Registrazione
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !isButtonEnabled) ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor: primaryColor.withOpacity(0.3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: isButtonEnabled ? 6 : 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3))
                                : Text(_isLogin ? 'Accedi' : 'Crea Account'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Switch Login/Registrazione
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? 'Non hai un account?' : 'Hai già un account?',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _acceptedTerms = false;
                                  if (_isLogin) {
                                    _firstNameController.clear();
                                    _lastNameController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                });
                              },
                              child: Text(
                                _isLogin ? 'Registrati' : 'Accedi',
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
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