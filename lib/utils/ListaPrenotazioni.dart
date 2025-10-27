
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magi_hair_off/features/authentication/services/auth_service.dart';

class ListaPrenotazioni extends StatefulWidget {
  const ListaPrenotazioni({super.key});

  @override
  State<ListaPrenotazioni> createState() => _ListaPrenotazioniState();
}

class _ListaPrenotazioniState extends State<ListaPrenotazioni> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _confirmCancelBooking(BuildContext context, Booking booking) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annulla Prenotazione'),
          content: Text('Sei sicuro di voler annullare la prenotazione per "${booking.treatment.name}" il ${DateFormat('dd/MM/yyyy HH:mm').format(booking.date)}?'),
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
    if (currentUser == null) {
      return const Center(child: Text('Accedi per vedere le tue prenotazioni.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le Tue Prenotazioni'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUser!.uid)
            .where('date', isGreaterThanOrEqualTo: DateTime.now())
            .orderBy('date', descending: false)
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

          // ✅ REVISIONE CRITICA QUI: Mappa correttamente i documenti
          final bookings = snapshot.data!.docs.map((doc) {
            // Assicurati che doc.data() sia effettivamente un Map<String, dynamic>
            // Il `!` dopo doc.data() è sicuro perché abbiamo già controllato !snapshot.hasData
            return Booking.fromJson(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Annulla prenotazione',
                        // ✅ Aggiunto controllo booking.id != null prima di passare a _confirmCancelBooking
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