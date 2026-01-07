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
        final primaryColor = Theme.of(context).primaryColor;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Annulla Prenotazione',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Sei sicuro di voler annullare la prenotazione per "${booking.treatment.name}" il ${DateFormat('dd/MM/yyyy HH:mm').format(booking.date)}?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, // Rosso più scuro per l'azione negativa
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Sì, Annulla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: primaryColor.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'Accedi per vedere le tue prenotazioni.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Effettua il login per visualizzare e gestire i tuoi appuntamenti futuri.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Sfondo leggero
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Le Tue Prenotazioni',
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
            elevation: 8, // Un po' di ombra per l'app bar
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUser!.uid)
                .where('date', isGreaterThanOrEqualTo: DateTime.now())
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: primaryColor)),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Errore nel caricamento: ${snapshot.error}', style: textTheme.bodyLarge?.copyWith(color: Colors.red))),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.calendarCheck, size: 80, color: primaryColor.withOpacity(0.6)), // Icona più pertinente
                        const SizedBox(height: 24),
                        Text(
                          'Nessuna prenotazione futura.',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sembra che tu non abbia appuntamenti imminenti. Che ne dici di prenotarne uno ora?',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bookings = snapshot.data!.docs.map((doc) {
                return Booking.fromJson(doc.data() as Map<String, dynamic>, doc.id);
              }).toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Padding generale maggiore
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final booking = bookings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10.0), // Margine verticale leggermente aumentato
                        elevation: 4, // Ombra coerente con HomePage
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bordi più arrotondati
                        child: Padding(
                          padding: const EdgeInsets.all(20.0), // Padding maggiore
                          child: Row(
                            children: [
                              // Icona del servizio (opzionale, per abbellire)
                              Icon(
                                booking.treatment.type == ServiceType.capelli ? FontAwesomeIcons.cut :
                                booking.treatment.type == ServiceType.unghie ? FontAwesomeIcons.handSparkles :
                                Icons.star_outline, // Icona di fallback per Speciali
                                color: primaryColor.withOpacity(0.8),
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.treatment.name,
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Con: ${booking.collaborator.name}',
                                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quando: ${DateFormat('EEE d MMM yyyy HH:mm', 'it_IT').format(booking.date)}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor, // Colore viola per la data
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(FontAwesomeIcons.trashCan, color: Colors.red.shade600, size: 24), // Icona più moderna
                                tooltip: 'Annulla prenotazione',
                                onPressed: booking.id != null ? () => _confirmCancelBooking(context, booking) : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: bookings.length,
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