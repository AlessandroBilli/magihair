import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:magi_hair_off/core/models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magi_hair_off/features/authentication/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key}); // ✅ NON richiede onLogoutAdmin

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isAdmin = false;
  Stream<DocumentSnapshot>? _userDocStream;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userDocStream = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots();
      _userDocStream!.listen((snapshot) {
        if (mounted) {
          setState(() {
            // ✅ CORREZIONE: Casting esplicito per snapshot.data()
            _isAdmin = snapshot.exists && (snapshot.data() as Map<String, dynamic>?)?['isAdmin'] == true;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = false;
        });
      }
    }
  }

  Future<void> _confirmCancelBooking(BuildContext context, Booking booking) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annulla Prenotazione (Admin)'),
          content: Text(
              'Sei sicuro di voler annullare la prenotazione di ${booking.userName ?? booking.userId} per "${booking.treatment.name}" il ${DateFormat('dd/MM/yyyy HH:mm').format(booking.date)}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sì, Annulla', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        if (booking.id == null) {
          throw Exception("ID della prenotazione non trovato per la cancellazione.");
        }
        await AuthService().cancelBooking(booking.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prenotazione annullata con successo!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nell\'annullamento: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Admin'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Accesso negato: non sei un amministratore.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Solo gli amministratori possono visualizzare questa sezione.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuna prenotazione futura.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs.map((doc) {
            return Booking.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              // ✅ CORREZIONE: Cast esplicito a Map<String, dynamic>
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final String userName = data['userName'] ?? 'ID: ${booking.userId}';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.treatment.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cliente: $userName',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Con: ${booking.collaborator.name}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quando: ${DateFormat('EEE d MMM yyyy HH:mm', 'it_IT').format(booking.date)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Cancella prenotazione (Admin)',
                        onPressed: booking.id != null ? () => _confirmCancelBooking(context, booking) : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}