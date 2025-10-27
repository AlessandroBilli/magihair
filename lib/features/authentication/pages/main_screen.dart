import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:magi_hair_off/main.dart';
import 'package:magi_hair_off/core/models.dart';
import 'package:magi_hair_off/features/authentication/pages/home_page.dart';
import 'package:magi_hair_off/utils/CreaPrenotazioni.dart';
import 'package:magi_hair_off/utils/ListaPrenotazioni.dart';
import 'package:magi_hair_off/utils/AdminDashBoardPage.dart';
import 'package:magi_hair_off/features/authentication/pages/profile_page.dart';
import 'package:magi_hair_off/features/authentication/services/auth_service.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  Stream<DocumentSnapshot>? _userDocStream; // Stream per ascoltare i cambiamenti del documento utente

  @override
  void initState() {
    super.initState();
    // ✅ Ascolta i cambiamenti dello stato di autenticazione dell'utente
    // per impostare o ripristinare lo stream del documento utente.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userDocStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
        _userDocStream!.listen((snapshot) {
          if (mounted) {
            setState(() {
              // ✅ CORREZIONE: Casting esplicito per snapshot.data()
              _isAdmin = snapshot.exists && (snapshot.data() as Map<String, dynamic>?)?['isAdmin'] == true;
              if (!_isAdmin && _selectedIndex == 2) {
                _selectedIndex = 0; // Torna alla home se l'utente non è più admin e si trovava nella dashboard
              }
            });
          }
        });
      } else {
        // Utente disconnesso
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _userDocStream = null;
            _selectedIndex = 0;
          });
        }
      }
    });
  }

  Future<void> _creaNuovaPrenotazione(List<Treatment> treatments, Treatment initialTreatment, String pageTitle) async {
    final bookingDetails = await Navigator.push<Booking>(context,
        MaterialPageRoute(builder: (context) => CreaPrenotazioni(
          pageTitle: pageTitle,
          treatments: treatments,
          initialTreatment: initialTreatment,
        )));

    final currentUser = FirebaseAuth.instance.currentUser;
    if (bookingDetails != null && currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      String userName = 'Sconosciuto'; // Default
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()! as Map<String, dynamic>; // ✅ CORREZIONE: CAST ESPLICITO QUI
        userName = userData['name'] ?? 'Sconosciuto';
      }

      final bookingToSave = Booking(
        userId: currentUser.uid,
        treatment: bookingDetails.treatment,
        date: bookingDetails.date,
        time: bookingDetails.time,
        collaborator: bookingDetails.collaborator,
        userName: userName, // Passa il nome utente alla prenotazione
      );
      await FirebaseFirestore.instance.collection('bookings').add(bookingToSave.toJson());
    }
  }

  void _onItemTapped(int index) {
    // Impedisce l'accesso alla dashboard admin se l'utente non è admin
    if (index == 2 && !_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accesso negato: devi essere un amministratore."), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      HomePage(
        onNavigateToBooking: (treatments, initialTreatment, pageTitle) =>
            _creaNuovaPrenotazione(treatments, initialTreatment, pageTitle),
      ),
      const ListaPrenotazioni(),
      const AdminDashboardPage(), // Indice 2 per la Dashboard Admin. ✅ Nessun parametro onLogoutAdmin qui.
      const ProfilePage(),
    ];

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Prenotazioni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
            tooltip: _isAdmin ? 'Dashboard Admin' : 'Accesso Admin (Solo per Amministratori)',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}