import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:magi_hair_off/main.dart'; // Probabilmente solo l'import del tema o del setup iniziale
import 'package:magi_hair_off/core/models.dart';
import 'package:magi_hair_off/features/authentication/pages/home_page.dart';
// Importiamo la classe corretta: CreaPrenotazioni
import 'package:magi_hair_off/utils/CreaPrenotazioni.dart';
import 'package:magi_hair_off/utils/ListaPrenotazioni.dart';
import 'package:magi_hair_off/utils/AdminDashBoardPage.dart';
import 'package:magi_hair_off/features/authentication/pages/profile_page.dart';
import 'package:magi_hair_off/features/authentication/services/auth_service.dart';
import 'package:magi_hair_off/features/authentication/pages/info_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  Stream<DocumentSnapshot>? _userDocStream;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userDocStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
        _userDocStream!.listen((snapshot) {
          if (mounted) {
            setState(() {
              _isAdmin = snapshot.exists && (snapshot.data() as Map<String, dynamic>?)?['isAdmin'] == true;
              // se l'utente non è più admin e l'indice selezionato era quello dell'admin dashboard,
              // riporta l'indice alla home. Questo gestisce il caso di revoca dei permessi in tempo reale.
              if (!_isAdmin && _selectedIndex == _getAdminDashboardIndex()) {
                _selectedIndex = 0;
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
            _selectedIndex = 0; // Torna alla home page quando l'utente si disconnette
          });
        }
      }
    });
  }

  //  Helper per ottenere l'indice della dashboard admin (indice 3 quando è presente)
  int _getAdminDashboardIndex() {
    return 3;
  }

  // =========================================================================
  // ✅ CORREZIONE CHIAVE: Allineamento della firma della funzione per accettare
  //    Treatment? (opzionale), e chiamata del costruttore con named parameters.
  // =========================================================================
  Future<void> _creaNuovaPrenotazione(
      List<Treatment> treatments,
      Treatment? initialTreatment, // ✅ RESO NULLABLE per maggiore robustezza
      String pageTitle
      ) async {
    final bookingDetails = await Navigator.push<Booking>(
        context,
        MaterialPageRoute(
            builder: (context) => CreaPrenotazioni(
              pageTitle: pageTitle, // ✅ Parametro named
              treatments: treatments, // ✅ Parametro named
              initialTreatment: initialTreatment, // ✅ Parametro named (opzionale)
            )));

    final currentUser = FirebaseAuth.instance.currentUser;
    if (bookingDetails != null && currentUser != null) {
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
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //  Liste dinamiche basate sullo stato _isAdmin
    final List<Widget> pages = [
      // Indice 0: InfoPage
      const InfoPage(),

      // Indice 1: HomePage (Selezione Servizi/Prenota)
      HomePage(
        onNavigateToBooking: (treatments, initialTreatment, pageTitle) =>
            _creaNuovaPrenotazione(treatments, initialTreatment, pageTitle),
      ),
      // Indice 2: ListaPrenotazioni
      const ListaPrenotazioni(),

      // Indice 3: ProfilePage
      const ProfilePage(),
    ];

    final List<BottomNavigationBarItem> navBarItems = [
      // Indice 0: Voce Info
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),

      // Indice 1: Voce Servizi/Prenota
      const BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Servizi',
      ),

      // Indice 2: Voce Prenotazioni
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Prenotazioni',
      ),

      // Indice 3: Voce Profilo
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profilo',
      ),
    ];


    if (_isAdmin) {
      // AdminDashboardPage viene inserita all'indice 3
      pages.insert(3, const AdminDashboardPage());

      // Voce Admin viene inserita all'indice 3
      navBarItems.insert(3,
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
          tooltip: 'Dashboard Admin',
        ),
      );
    }

    // Assicurati che _selectedIndex non vada oltre il numero di pagine disponibili
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0; // Torna alla home (InfoPage) se l'indice corrente non è più valido
    }

    return Scaffold(
      body: Center(
        child: pages.elementAt(_selectedIndex), // Usa la lista 'pages' dinamica
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems, // Usa la lista 'navBarItems' dinamica
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Mantiene le label visibili anche con 4+ item
      ),
    );
  }
}