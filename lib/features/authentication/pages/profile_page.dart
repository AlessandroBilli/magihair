import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- NECESSARIO PER CHIUDERE L'APP
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
  String _userPhone = 'Caricamento...';
  bool _isAdmin = false;

  StreamSubscription<DocumentSnapshot>? _userStreamSubscription;
  final TextEditingController _nameEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    _nameEditController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    if (currentUser != null) {
      _userStreamSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .snapshots()
          .listen(
            (snapshot) {
          if (mounted) {
            setState(() {
              if (snapshot.exists && snapshot.data() != null) {
                final userData = snapshot.data()! as Map<String, dynamic>;
                _userName = userData['name'] ?? 'Nome non disponibile';
                _userPhone = userData['phoneNumber'] ?? 'Numero non disponibile';
                _isAdmin = userData['isAdmin'] == true;
                _nameEditController.text = _userName;
              } else {
                _userName = 'Utente Sconosciuto';
                _userPhone = 'Non disponibile';
                _isAdmin = false;
              }
            });
          }
        },
        onError: (error) {
          print("Stream interrotto (normal during delete): $error");
        },
      );
    } else {
      if (mounted) {
        setState(() {
          _userName = 'Nessun utente loggato';
          _userPhone = 'N/A';
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _userStreamSubscription?.cancel();
      await AuthService().signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore logout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateUserName() async {
    if (currentUser == null || _nameEditController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'name': _nameEditController.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome aggiornato!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifica Nome'),
        content: TextField(controller: _nameEditController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(onPressed: _updateUserName, child: const Text('Salva')),
        ],
      ),
    );
  }

  // ==================================================================
  // 🟢 FUNZIONE ELIMINA ACCOUNT (METODO "CHIUDI APP")
  // ==================================================================
  Future<void> _deleteAccountSecurely() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Eliminazione Account"),
          // ⚠️ MESSAGGIO AGGIORNATO COME RICHIESTO
          content: const Text(
            "Questa azione eliminerà definitivamente il tuo account e i tuoi dati.\n\n"
                "⚠️ IMPORTANTE: Per completare l'operazione e accedere con un nuovo account, sarà necessario chiudere e riavviare l'applicazione.",
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annulla")),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("HO CAPITO, ELIMINA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            ),
          ],
        )
    );

    if (confirm == true) {
      if (!mounted) return;

      // Mostra caricamento non chiudibile
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator())
      );

      // Stacchiamo subito la spina dai dati
      await _userStreamSubscription?.cancel();
      _userStreamSubscription = null;

      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          // Elimina
          await AuthService().deleteAccount(uid);
        }
      } catch (e) {
        print("Errore delete (ignorabile): $e");
      } finally {
        // ==============================================================
        // 🚀 CHIUSURA FORZATA DELL'APP
        // Invece di provare a navigare, chiudiamo l'app così l'utente
        // è costretto a riaprirla "pulita".
        // ==============================================================
        if (mounted) {
          // Prova a chiudere l'app (Funziona su Android)
          SystemNavigator.pop();

          // Se siamo su iOS o il pop fallisce, proviamo a tornare al login come piano B
          // dopo un piccolo ritardo
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(); // Chiude loader
            try { await FirebaseAuth.instance.signOut(); } catch (_) {}
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Il Mio Profilo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: primaryColor,
            automaticallyImplyLeading: false,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(FontAwesomeIcons.solidCircleUser, size: 100, color: primaryColor.withOpacity(0.8)),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _showEditNameDialog,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text('Modifica Nome', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  ),
                  const SizedBox(height: 30),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.person, 'Nome', _userName, primaryColor, isBold: true),
                          const Divider(height: 30),
                          _buildInfoRow(Icons.phone, 'Telefono', _userPhone, Colors.blueGrey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Esci', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 30),

                  TextButton.icon(
                    onPressed: _deleteAccountSecurely,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text("Elimina il mio account", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color.withOpacity(0.8)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}