import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:magi_hair_off/core/models.dart';
import 'package:magi_hair_off/features/authentication/pages/home_page.dart';
import 'package:magi_hair_off/utils/CreaPrenotazioni.dart';
import 'package:magi_hair_off/utils/ListaPrenotazioni.dart';
import 'package:magi_hair_off/utils/AdminDashBoardPage.dart';
import 'package:magi_hair_off/features/authentication/pages/profile_page.dart';
import 'package:magi_hair_off/features/authentication/pages/info_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  // 🟢 CORREZIONE: Variabili per gestire la chiusura degli stream
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      // Puliamo sempre il vecchio listener del documento utente
      _userDocSubscription?.cancel();
      _userDocSubscription = null;

      if (user != null) {
        _userDocSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          if (mounted) {
            setState(() {
              _isAdmin = snapshot.exists && (snapshot.data() as Map<String, dynamic>?)?['isAdmin'] == true;
              if (!_isAdmin && _selectedIndex == 3) {
                _selectedIndex = 0;
              }
            });
          }
        }, onError: (e) {
          print("Errore stream MainScreen (ignorabile se eliminato): $e");
        });
      } else {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _selectedIndex = 0;
          });
        }
      }
    });
  }

  // 🟢 FONDAMENTALE: Questo metodo impedisce il buffering eterno
  @override
  void dispose() {
    _userDocSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _creaNuovaPrenotazione(
      List<Treatment> treatments,
      Treatment? initialTreatment,
      String pageTitle
      ) async {
    final bookingDetails = await Navigator.push<Booking>(
        context,
        MaterialPageRoute(
            builder: (context) => CreaPrenotazioni(
              pageTitle: pageTitle,
              treatments: treatments,
              initialTreatment: initialTreatment,
            )));

    final currentUser = FirebaseAuth.instance.currentUser;
    if (bookingDetails != null && currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        String userName = 'Sconosciuto';
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()! as Map<String, dynamic>;
          userName = userData['name'] ?? 'Sconosciuto';
        }

        final bookingToSave = Booking(
          userId: currentUser.uid,
          treatment: bookingDetails.treatment,
          date: bookingDetails.date,
          time: bookingDetails.time,
          collaborator: bookingDetails.collaborator,
          userName: userName,
        );
        await FirebaseFirestore.instance.collection('bookings').add(bookingToSave.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prenotazione creata con successo!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print("Errore salvataggio prenotazione: $e");
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const InfoPage(),
      HomePage(
        onNavigateToBooking: (treatments, initialTreatment, pageTitle) =>
            _creaNuovaPrenotazione(treatments, initialTreatment, pageTitle),
      ),
      const ListaPrenotazioni(),
      const ProfilePage(),
    ];

    final List<BottomNavigationBarItem> navBarItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Servizi'),
      const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Prenotazioni'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilo'),
    ];

    if (_isAdmin) {
      pages.insert(3, const AdminDashboardPage());
      navBarItems.insert(3, const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
    }

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      body: Center(child: pages.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}