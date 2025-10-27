import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:magi_hair_off/features/authentication/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _userName = 'Caricamento...';
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
              final userData = snapshot.data()! as Map<String, dynamic>; // ✅ CORREZIONE: CAST ESPLICITO QUI
              _userName = userData['name'] ?? 'Nome non disponibile';
              _isAdmin = userData['isAdmin'] == true;
              _nameEditController.text = _userName;
            } else {
              _userName = 'Utente Sconosciuto';
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
          SnackBar(content: Text('Errore durante il logout: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateUserName() async {
    if (currentUser == null || _nameEditController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Il nome non può essere vuoto.'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Nome aggiornato con successo!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nell\'aggiornamento del nome: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica il tuo Nome'),
          content: TextField(
            controller: _nameEditController,
            decoration: const InputDecoration(labelText: 'Nuovo Nome'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameEditController.text = _userName;
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: _updateUserName,
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Il Mio Profilo'),
        automaticallyImplyLeading: false,
      ),
      body: currentUser == null
          ? const Center(child: Text('Accedi per visualizzare il tuo profilo.'))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showEditNameDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifica Nome'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nome: $_userName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Email: ${currentUser!.email ?? 'Non disponibile'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Ruolo: ${_isAdmin ? 'Amministratore' : 'Utente Standard'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isAdmin ? Colors.green.shade700 : Colors.blueGrey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}