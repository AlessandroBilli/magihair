import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _FIREBASE_AUTH_DOMAIN = '@magihair.app';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _maskPhoneToEmail(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone + _FIREBASE_AUTH_DOMAIN;
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<User?> signUpWithPhone(String phoneNumber, String password, String name) async {
    try {
      final maskedEmail = _maskPhoneToEmail(phoneNumber);
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: maskedEmail,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'phoneNumber': phoneNumber,
        'name': name,
        'createdAt': Timestamp.now(),
      });
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Errore registrazione: ${e.message}");
      rethrow;
    }
  }

  Future<User?> signInWithPhonePassword(String phoneNumber, String password) async {
    try {
      final maskedEmail = _maskPhoneToEmail(phoneNumber);
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: maskedEmail,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Errore login: ${e.message}");
      rethrow;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', false);
    await _auth.signOut();
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      print("Errore durante la cancellazione della prenotazione: $e");
      rethrow;
    }
  }

  // 🟢 AGGIUNTO: Funzione fondamentale per eliminare l'account
  Future<void> deleteAccount(String userId) async {
    try {
      // 1. Elimina i dati da Firestore
      await _firestore.collection('users').doc(userId).delete();
      // 2. Elimina l'utente dall'Autenticazione
      await _auth.currentUser?.delete();
    } catch (e) {
      print("Errore deleteAccount: $e");
      rethrow;
    }
  }
}