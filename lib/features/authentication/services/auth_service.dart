import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ Dominio fittizio richiesto per l'autenticazione Email/Password di Firebase
// Usiamo un dominio univoco per mascherare il numero di telefono e superare la validazione di Firebase.
const String _FIREBASE_AUTH_DOMAIN = '@magihair.app';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Funzione helper per mascherare il numero in un ID accettabile da Firebase
  String _maskPhoneToEmail(String phoneNumber) {
    // Pulisce il numero da caratteri non numerici (spazi, trattini, etc.)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone + _FIREBASE_AUTH_DOMAIN;
  }

  // Ottiene l'utente corrente di Firebase
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // =========================================================================
  // REGISTRAZIONE con Numero di Telefono, Password e Nome (signUpWithPhone)
  // =========================================================================
  Future<User?> signUpWithPhone(String phoneNumber, String password, String name) async {
    try {
      // 1. Maschera il numero per soddisfare il formato email di Firebase
      final maskedEmail = _maskPhoneToEmail(phoneNumber);

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        // Usiamo l'email mascherata per l'Auth (es: 3331234567@magihair.app)
        email: maskedEmail,
        password: password,
      );

      // 2. Salva l'utente in Firestore con i dati reali
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'phoneNumber': phoneNumber, // Salviamo il numero reale non mascherato
        'name': name, // Salviamo il nome utente obbligatorio
        'createdAt': Timestamp.now(),
      });
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Errore registrazione: ${e.message}");
      rethrow;
    }
  }

  // =========================================================================
  // ACCESSO con Numero di Telefono e Password (signInWithPhonePassword)
  // =========================================================================
  Future<User?> signInWithPhonePassword(String phoneNumber, String password) async {
    try {
      // 1. Maschera il numero per soddisfare il formato email di Firebase
      final maskedEmail = _maskPhoneToEmail(phoneNumber);

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: maskedEmail, // Usiamo l'email mascherata per il login
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Errore login: ${e.message}");
      rethrow;
    }
  }
// -------------------------------------------------------------------------

  // Logout (con pulizia dello stato admin)
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', false);
    await _auth.signOut();
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
      print("Prenotazione con ID $bookingId cancellata con successo.");
    } catch (e) {
      print("Errore durante la cancellazione della prenotazione: $e");
      rethrow;
    }
  }
}