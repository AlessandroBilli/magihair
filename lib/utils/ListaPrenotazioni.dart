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

  // Funzione per confermare la cancellazione
  Future<void> _confirmCancelBooking(BuildContext context, Booking booking) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final primaryColor = Theme.of(context).primaryColor;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Annulla Prenotazione',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Sei sicuro di voler annullare la prenotazione per "${booking.treatment.name}" il ${DateFormat('dd/MM/yyyy HH:mm').format(booking.date)}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Sì, Annulla'),
            ),
          ],
        );
      },
    );

    if (confirm == true && booking.id != null) {
      try {
        await AuthService().cancelBooking(booking.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prenotazione annullata!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    // Se l'utente non è loggato
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text('Effettua il login per vedere le tue prenotazioni.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Le Tue Prenotazioni', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: primaryColor,
            floating: true,
            pinned: true,
            elevation: 4,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUser!.uid)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              // 1. Gestione caricamento
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // 2. Gestione errore
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Errore: ${snapshot.error}')),
                );
              }

              // 3. Gestione lista vuota
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.calendarCheck, size: 60, color: primaryColor.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('Nessuna prenotazione trovata.'),
                      ],
                    ),
                  ),
                );
              }

              // 4. Se arriviamo qui, i dati ci sono!
              final bookingsDocs = snapshot.data!.docs;

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final doc = bookingsDocs[index];
                      final data = doc.data() as Map<String, dynamic>?;

                      if (data == null) return const SizedBox.shrink();

                      // Creiamo l'oggetto booking in modo sicuro
                      final booking = Booking.fromJson(data, doc.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Icon(FontAwesomeIcons.clock, color: primaryColor, size: 20),
                          ),
                          title: Text(
                            booking.treatment.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Con: ${booking.collaborator.name}'),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEE d MMM yyyy - HH:mm', 'it_IT').format(booking.date),
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(FontAwesomeIcons.trashCan, color: Colors.red),
                            onPressed: () => _confirmCancelBooking(context, booking),
                          ),
                        ),
                      );
                    },
                    childCount: bookingsDocs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}