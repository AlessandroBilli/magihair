import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magi_hair_off/main.dart';
import '../../../utils/CreaPrenotazioni.dart';
import '../../../core/models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final void Function(List<Treatment> allTreatments, Treatment initialTreatment, String pageTitle) onNavigateToBooking;

  const HomePage({super.key, required this.onNavigateToBooking});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // =======================================================
  // 🔔 LOGICA NOTIFICHE ADMIN (DIAGNOSTICA VISIBILE A SCHERMO)
  // =======================================================
  void setupNotificheAdmin() {
    // Usiamo addPostFrameCallback per essere sicuri che la pagina sia caricata
    // prima di mostrare eventuali messaggi a schermo.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 1. CHIEDIAMO SUBITO I PERMESSI, senza aspettare nient'altro
        NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // 2. CONTROLLIAMO SE C'È UN UTENTE LOGGATO
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          // Se non è loggato, non mostriamo nulla per non infastidire un cliente normale
          return;
        }

        // 3. CONTROLLIAMO SE L'UTENTE È ADMIN NEL DB
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data()?['isAdmin'] == true) {
          // 4. SINTONIZZAZIONE
          await FirebaseMessaging.instance.subscribeToTopic('admin_bookings');

          // 🎉 MOSTRA IL SUCCESSO SULLO SCHERMO DEL TELEFONO
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Sistema Notifiche Admin Attivo!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // L'utente è loggato ma non è admin. Nessuna notifica per lui.
          print("Utente non admin, sintonizzazione saltata.");
        }

      } catch (e) {
        // 🚨 SE C'È UN ERRORE, LO STAMPA SUL TELEFONO
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Errore Notifiche: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Avviamo il motore
    setupNotificheAdmin();

    // Mostra il popup in alto se l'app è aperta mentre qualcuno prenota
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🔔 ${message.notification?.title ?? "Nuova prenotazione!"}\n${message.notification?.body ?? ""}"),
            backgroundColor: Theme.of(context).primaryColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  // =======================================================
  // ✂️ LISTINO TRATTAMENTI E LOGICA UI (CARROZZERIA INTONSA)
  // =======================================================
  ServiceType _selectedServiceType = ServiceType.capelli;

  static const List<Treatment> _allTreatments = [
    Treatment(name: 'Taglio + Messa in piega', price: 35.0, type: ServiceType.combo, durationInMinutes: 60),
    Treatment(name: 'Colore + Messa in piega', price: 42.0, type: ServiceType.combo, durationInMinutes: 90),
    Treatment(name: 'Colore + Taglio + Messa in piega', price: 62.0, type: ServiceType.combo, durationInMinutes: 120),
    Treatment(name: 'Colpi di sole + Piega (da 55€)', price: 55.0, type: ServiceType.combo, durationInMinutes: 120),
    Treatment(name: 'Colpi di sole + Taglio + Piega (da 55€)', price: 55.0, type: ServiceType.combo, durationInMinutes: 150),
    Treatment(name: 'Trattamenti + Messa in piega', price: 50.0, type: ServiceType.combo, durationInMinutes: 75),
    Treatment(name: 'Permanente + Taglio + Piega', price: 70.0, type: ServiceType.combo, durationInMinutes: 150),
    Treatment(name: 'Colore senza ammoniaca + Piega', price: 45.0, type: ServiceType.combo, durationInMinutes: 90),
    Treatment(name: 'Balayage + Messa in piega', price: 95.0, type: ServiceType.combo, durationInMinutes: 210),
    Treatment(name: 'Messa in piega + ferri', price: 18.0, type: ServiceType.combo, durationInMinutes: 45),

    Treatment(name: 'Messa in piega (singola)', price: 15.0, type: ServiceType.capelli, durationInMinutes: 30),
    Treatment(name: 'Taglio', price: 10.0, type: ServiceType.capelli, durationInMinutes: 30),
    Treatment(name: 'Bagno di colore', price: 20.0, type: ServiceType.capelli, durationInMinutes: 45),
    Treatment(name: 'Ritocco di colore', price: 20.0, type: ServiceType.capelli, durationInMinutes: 60),
    Treatment(name: 'Cambio di colore', price: 27.0, type: ServiceType.capelli, durationInMinutes: 75),
    Treatment(name: 'Pigmenti', price: 20.0, type: ServiceType.capelli, durationInMinutes: 45),
    Treatment(name: 'Colpi di sole (singolo)', price: 15.0, type: ServiceType.capelli, durationInMinutes: 90),
    Treatment(name: 'Balayage (singolo)', price: 80.0, type: ServiceType.capelli, durationInMinutes: 180),
    Treatment(name: 'Meches con cuffia', price: 50.0, type: ServiceType.capelli, durationInMinutes: 120),
    Treatment(name: 'Colore senza ammoniaca (singolo)', price: 20.0, type: ServiceType.capelli, durationInMinutes: 60),
    Treatment(name: 'Permanente (singola)', price: 30.0, type: ServiceType.capelli, durationInMinutes: 90),
    Treatment(name: 'Tiraggio o anticrespo', price: 30.0, type: ServiceType.capelli, durationInMinutes: 90),
    Treatment(name: 'Ricostruzione profonda', price: 35.0, type: ServiceType.capelli, durationInMinutes: 45),
    Treatment(name: 'Laminazione', price: 35.0, type: ServiceType.capelli, durationInMinutes: 45),
    Treatment(name: 'Shampoo e fiale anticaduta', price: 35.0, type: ServiceType.capelli, durationInMinutes: 40),
    Treatment(name: 'Trattamento extra', price: 20.0, type: ServiceType.capelli, durationInMinutes: 30),
    Treatment(name: 'Extra Applicazione', price: 3.0, type: ServiceType.capelli, durationInMinutes: 15),

    Treatment(name: 'Semipermanente', price: 22.0, type: ServiceType.unghie, durationInMinutes: 60),
    Treatment(name: 'Semipermanente rinforzato', price: 27.0, type: ServiceType.unghie, durationInMinutes: 75),
    Treatment(name: 'Manicure + smalto', price: 15.0, type: ServiceType.unghie, durationInMinutes: 45),
    Treatment(name: 'Decorazione ad unghia', price: 3.0, type: ServiceType.unghie, durationInMinutes: 15),
    Treatment(name: 'Ricostruzione con allungamento (Gel)', price: 57.0, type: ServiceType.unghie, durationInMinutes: 120),
    Treatment(name: 'Ritocco/Refil (Gel)', price: 37.0, type: ServiceType.unghie, durationInMinutes: 90),
    Treatment(name: 'Ricostruzione ad unghia (Gel)', price: 4.0, type: ServiceType.unghie, durationInMinutes: 30),
    Treatment(name: 'Baffi + sopracciglia (Estetica)', price: 10.0, type: ServiceType.unghie, durationInMinutes: 30),

    Treatment(name: 'Solarium', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
    Treatment(name: 'Estetista', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
    Treatment(name: 'Dermopigmentista', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
    Treatment(name: 'Lashmaker', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
    Treatment(name: 'Operatore Olistica', price: 0, type: ServiceType.Speciali, durationInMinutes: 0),
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Treatment _prepareTreatmentForBooking(Treatment originalTreatment) {
    if (originalTreatment.type == ServiceType.combo) {
      return Treatment(
        name: originalTreatment.name,
        price: originalTreatment.price,
        type: ServiceType.capelli,
        durationInMinutes: originalTreatment.durationInMinutes,
      );
    }
    return originalTreatment;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTreatments = _allTreatments.where((t) => t.type == _selectedServiceType).toList();
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            snap: false,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16.0),
              title: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ServiceType.values.map((type) {
                    String label;
                    IconData icon;
                    switch (type) {
                      case ServiceType.capelli:
                        label = 'Parrucchiera';
                        icon = FontAwesomeIcons.cut;
                        break;
                      case ServiceType.combo:
                        label = ' Combo';
                        icon = FontAwesomeIcons.tags;
                        break;
                      case ServiceType.unghie:
                        label = 'Onicotecnica';
                        icon = FontAwesomeIcons.handSparkles;
                        break;
                      case ServiceType.Speciali:
                        label = 'Servizi su Chiamata';
                        icon = Icons.phone_in_talk;
                        break;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _selectedServiceType == type,
                        selectedColor: Colors.white,
                        backgroundColor: primaryColor.withOpacity(0.8),
                        labelStyle: TextStyle(
                          color: _selectedServiceType == type ? primaryColor : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide(color: Colors.white.withOpacity(0.7)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedServiceType = type;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: primaryColor.withOpacity(0.8),
                      alignment: Alignment.center,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor.withOpacity(0.6),
                          primaryColor.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 50.0),
                      child: Image.asset(
                        'assets/img/Logooffmagi.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.cut,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedServiceType == ServiceType.unghie)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_rounded, color: primaryColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Vuoi prenotare con Giorgia?",
                              style: textTheme.titleMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Attualmente le prenotazioni per Giorgia non sono disponibili tramite app. Ti invitiamo a chiamare in salone.",
                        style: textTheme.bodyMedium?.copyWith(
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall('+393888106944'),
                          icon: const Icon(Icons.call, color: Colors.white, size: 18),
                          label: const Text("Chiama per Giorgia"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_selectedServiceType == ServiceType.capelli)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.people_alt_rounded, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Informazione Staff",
                              style: textTheme.titleMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Se trovi l'operatore \"Ragazza\" durante la prenotazione, indica un membro dello staff presente in turno ma non specificato nominalmente.",
                              style: textTheme.bodyMedium?.copyWith(
                                color: primaryColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_selectedServiceType == ServiceType.Speciali)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Card(
                  color: primaryColor.withOpacity(0.1),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: primaryColor.withOpacity(0.4), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.phone_in_talk, size: 50, color: primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          "Servizi Specialistici su Richiesta",
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Questi trattamenti richiedono la presenza di specialisti esterni. Per informazioni su costi, disponibilità e per prenotare, è necessaria una consulenza telefonica.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _makePhoneCall('+393888106944'),
                          icon: const Icon(Icons.call, color: Colors.white),
                          label: const Text('Chiama per Informazioni', style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 5,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_selectedServiceType == ServiceType.combo)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Le combinazioni più richieste",
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final treatment = filteredTreatments[index];

                  IconData serviceIcon;
                  if (treatment.type == ServiceType.capelli || treatment.type == ServiceType.combo) {
                    serviceIcon = FontAwesomeIcons.cut;
                  } else if (treatment.type == ServiceType.unghie) {
                    serviceIcon = FontAwesomeIcons.handSparkles;
                  } else {
                    serviceIcon = Icons.star_outline;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide.none,
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(
                            serviceIcon,
                            color: primaryColor.withOpacity(0.8),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  treatment.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (treatment.durationInMinutes > 0)
                                  Text(
                                    'Durata: ${treatment.durationInMinutes} min',
                                    style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                if (treatment.price > 0)
                                  Text(
                                    'Costo: €${treatment.price.toStringAsFixed(2)}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (treatment.type != ServiceType.Speciali)
                            ElevatedButton.icon(
                              onPressed: () => widget.onNavigateToBooking(
                                _allTreatments,
                                _prepareTreatmentForBooking(treatment),
                                'Prenota ${treatment.name}',
                              ),
                              icon: const Icon(Icons.calendar_month, size: 18, color: Colors.white),
                              label: const Text('Prenota', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 3,
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
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
