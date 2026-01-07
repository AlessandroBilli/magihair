import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:magi_hair_off/features/authentication/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _userName = 'Caricamento...';
  // 🟢 NUOVO: Variabile per memorizzare il numero di telefono
  String _userPhone = 'Caricamento...';
  bool _isAdmin = false;
  Stream<DocumentSnapshot>? _userDocStream;
  final TextEditingController _nameEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameEditController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    if (currentUser != null) {
      _userDocStream = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots();
      _userDocStream!.listen((snapshot) {
        if (mounted) {
          setState(() {
            if (snapshot.exists && snapshot.data() != null) {
              final userData = snapshot.data()! as Map<String, dynamic>;

              // Recupera Nome
              _userName = userData['name'] ?? 'Nome non disponibile';
              _nameEditController.text = _userName;

              // 🟢 Recupera Numero di Telefono (chiave 'phoneNumber' salvata in AuthService)
              _userPhone = userData['phoneNumber'] ?? 'Numero non disponibile';

              _isAdmin = userData['isAdmin'] == true;
            } else {
              _userName = 'Utente Sconosciuto';
              _userPhone = 'Non disponibile';
              _isAdmin = false;
              _nameEditController.text = _userName;
            }
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _userName = 'Nessun utente loggato';
          _userPhone = 'N/A';
          _isAdmin = false;
          _nameEditController.text = _userName;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il logout: ${e.toString()}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateUserName() async {
    if (currentUser == null || _nameEditController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Il nome non può essere vuoto.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'name': _nameEditController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome aggiornato con successo!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Chiude il dialog dopo il salvataggio
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nell\'aggiornamento del nome: ${e.toString()}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditNameDialog() {
    final primaryColor = Theme.of(context).primaryColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Modifica il tuo Nome',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _nameEditController,
            decoration: InputDecoration(
              labelText: 'Nuovo Nome',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameEditController.text = _userName; // Reset al nome originale
                Navigator.of(context).pop();
              },
              child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: _updateUserName,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Il Mio Profilo',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            floating: true,
            pinned: true,
            elevation: 8,
          ),
          if (currentUser == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: 80, color: primaryColor.withOpacity(0.6)),
                    const SizedBox(height: 24),
                    Text(
                      'Accedi per visualizzare il tuo profilo.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Le tue informazioni personali saranno disponibili dopo il login.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0), // Padding generale aumentato
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Centra tutti gli elementi nella colonna
                  children: [
                    // Icona utente o avatar
                    Icon(
                      FontAwesomeIcons.solidCircleUser,
                      size: 100,
                      color: primaryColor.withOpacity(0.8),
                    ),
                    const SizedBox(height: 20),

                    // Pulsante Modifica Nome
                    ElevatedButton.icon(
                      onPressed: _showEditNameDialog,
                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                      label: const Text('Modifica Nome', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Card con le informazioni del profilo
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Centra il contenuto della Card
                          children: [
                            _buildProfileInfoRow(
                              context,
                              icon: Icons.person_outline,
                              label: 'Nome',
                              value: _userName,
                              color: primaryColor,
                              isBoldValue: true,
                            ),
                            const Divider(height: 30), // Divisore elegante
                            // 🟢 RIGA AGGIORNATA PER MOSTRARE IL NUMERO DI TELEFONO
                            _buildProfileInfoRow(
                              context,
                              icon: Icons.phone, // Icona telefono
                              label: 'Numero di Telefono', // Etichetta Numero di Telefono
                              value: _userPhone, // ⬅️ Usa il numero di telefono caricato
                              color: Colors.blueGrey.shade700,
                            ),
                            const Divider(height: 30),

                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Pulsante Esci
                    ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Esci',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method per costruire le righe delle informazioni del profilo
  Widget _buildProfileInfoRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required Color color,
        bool isBoldValue = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Centra l'icona e il testo
      children: [
        Icon(icon, size: 30, color: color.withOpacity(0.8)),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: isBoldValue
              ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)
              : Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade800),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}