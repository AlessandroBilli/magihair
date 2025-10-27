import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Aggiunto per formattare la data
import 'package:magi_hair_off/main.dart';
import '../../../utils/CreaPrenotazioni.dart';
import '../../../core/models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  // ✅ MODIFICA: Aggiunto il tipo della funzione onNavigateToBooking
  final void Function(List<Treatment> allTreatments, Treatment initialTreatment, String pageTitle) onNavigateToBooking;

  const HomePage({super.key, required this.onNavigateToBooking});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ServiceType _selectedServiceType = ServiceType.capelli; // Tipo di servizio selezionato di default

  // Lista completa di tutti i trattamenti offerti
  // ✅ MODIFICA: La lista _allTreatments è stata spostata in _HomePageState per essere coerente
  // con la versione di models.dart e per essere usata come lista completa per la navigazione.
  static const List<Treatment> _allTreatments = [
    // --- Servizi Capelli ---
    Treatment(name: 'Messa in piega', price: 25.0, type: ServiceType.capelli, durationInMinutes: 40),
    Treatment(name: 'Colore e piega', price: 60.0, type: ServiceType.capelli, durationInMinutes: 90),
    Treatment(name: 'Colore, taglio e piega', price: 85.0, type: ServiceType.capelli, durationInMinutes: 120),
    Treatment(name: 'Colpi di sole, taglio e piega', price: 120.0, type: ServiceType.capelli, durationInMinutes: 180),
    Treatment(name: 'Balayage, taglio e piega', price: 150.0, type: ServiceType.capelli, durationInMinutes: 240),

    // --- Servizi Onicotecnica ---
    Treatment(name: 'Manicure Classica', price: 20.0, type: ServiceType.unghie, durationInMinutes: 45),
    Treatment(name: 'Ricostruzione Gel', price: 50.0, type: ServiceType.unghie, durationInMinutes: 120),
    Treatment(name: 'Smalto Semipermanente', price: 30.0, type: ServiceType.unghie, durationInMinutes: 60),

    // --- Servizi Speciali (corretto da "su Chiamata") ---
    // ✅ MODIFICA: Cambiato ServiceType.Speciali in ServiceType.speciali
    Treatment(name: 'Solarium', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
    Treatment(name: 'Dermopigmentista', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
    Treatment(name: 'Lashmaker', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
    Treatment(name: 'Operatore Olistica', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
  ];

  // Funzione per avviare la chiamata telefonica
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // In caso di errore (es. dispositivo senza funzione telefono)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile effettuare la chiamata')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtra i trattamenti in base al tipo di servizio selezionato
    final filteredTreatments = _allTreatments.where((t) => t.type == _selectedServiceType).toList();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text("Servizi"),
            floating: true,
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight + 10, bottom: 10),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: ServiceType.values.map((type) {
                        String label;
                        switch (type) {
                          case ServiceType.capelli:
                            label = 'Capelli';
                            break;
                          case ServiceType.unghie:
                            label = 'Unghie';
                            break;
                          case ServiceType.Speciali: // ✅ MODIFICA: Cambiato ServiceType.Speciali in ServiceType.speciali
                            label = 'Servizi su Chiamata';
                            break;
                        }
                        return ChoiceChip(
                          label: Text(label),
                          selected: _selectedServiceType == type,
                          selectedColor: primaryColor,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: _selectedServiceType == type ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedServiceType = type;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Sezione descrittiva e pulsante per i "Servizi su Chiamata"
          if (_selectedServiceType == ServiceType.Speciali) // ✅ MODIFICA: Cambiato ServiceType.Speciali in ServiceType.speciali
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Card(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "Come Funzionano",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: primaryColor),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Questi trattamenti richiedono la presenza di specialisti esterni. Per informazioni su costi, disponibilità e per prenotare, è necessaria una consulenza telefonica.",
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _makePhoneCall('+390123456789'), // ⚠️ SOSTITUISCI QUI CON IL TUO NUMERO REALE
                          icon: const Icon(Icons.phone_forwarded),
                          label: const Text('Chiama per Informazioni'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Lista dei servizi disponibili
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final treatment = filteredTreatments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  treatment.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                if (treatment.durationInMinutes > 0)
                                  Text('Durata: ${treatment.durationInMinutes} min', style: Theme.of(context).textTheme.bodySmall),
                                if (treatment.price > 0)
                                  Text('Costo: €${treatment.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),

                          // Logica condizionale per il pulsante "Prenota"
                          if (treatment.type == ServiceType.Speciali) // ✅ MODIFICA: Cambiato ServiceType.Speciali in ServiceType.speciali
                            const SizedBox.shrink() // Nessun pulsante "Prenota" per i servizi su chiamata
                          else
                            ElevatedButton.icon(
                              onPressed: () => widget.onNavigateToBooking(
                                // ✅ MODIFICA: Passa _allTreatments completo
                                _allTreatments,
                                // Poi il trattamento specifico cliccato (per preselezione)
                                treatment,
                                // Infine il titolo della pagina
                                'Prenota ${treatment.name}',
                              ),
                              icon: const Icon(Icons.calendar_month, size: 18),
                              label: const Text('Prenota'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredTreatments.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}