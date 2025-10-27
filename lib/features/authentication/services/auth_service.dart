import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ottiene l'utente corrente di Firebase
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Registrazione con email e password
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Salva l'utente anche in Firestore (collezione 'users')
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'createdAt': Timestamp.now(),
      });
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Errore registrazione: ${e.message}");
      rethrow; // Rilancia l'eccezione per essere gestita dalla UI
    }
  }

  // Accesso con email e password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Errore login: ${e.message}");
      rethrow; // Rilancia l'eccezione per essere gestita dalla UI
    }
  }

  // Logout (con pulizia dello stato admin)
  Future<void> signOut() async {
    // Pulisci lo stato di admin dal dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', false);

    // Esegui il logout da Firebase
    await _auth.signOut();
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
      print("Prenotazione con ID $bookingId cancellata con successo.");
    } catch (e) {
      print("Errore durante la cancellazione della prenotazione: $e");
      rethrow; // Rilancia l'errore per gestirlo nell'UI
    }
  }
}