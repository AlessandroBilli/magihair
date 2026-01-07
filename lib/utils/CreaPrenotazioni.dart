import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models.dart';
import 'BuisnessHours.dart';
import 'dart:async'; // Necessario per StreamSubscription

class CreaPrenotazioni extends StatefulWidget {
  final String pageTitle;
  final List<Treatment> treatments;
  final Treatment? initialTreatment;

  const CreaPrenotazioni({
    super.key,
    required this.pageTitle,
    required this.treatments,
    this.initialTreatment,
  });

  @override
  State<CreaPrenotazioni> createState() => _CreaPrenotazioniState();
}

class _CreaPrenotazioniState extends State<CreaPrenotazioni> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Booking> _todaysBookings = [];
  bool _isLoadingBookings = false;
  // 🟢 NUOVO: Usiamo uno StreamSubscription per ascoltare in tempo reale
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  List<Collaborator> _allCollaborators = [];
  bool _isLoadingCollaborators = true;
  List<DateTime> _closureDays = [];

  final Map<int, String> _firestoreDayKeys = {
    1: '1', 2: '2', 3: '3', 4: '4', 5: '5', 6: '6', 7: '7',
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchCollaborators();
    _fetchBusinessClosures();
    // Avviamo l'ascolto in tempo reale per oggi
    _listenToBookingsForDay(_focusedDay);
  }

  @override
  void dispose() {
    // 🟢 NUOVO: Chiudiamo il canale quando usciamo dalla pagina per evitare sprechi
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  ServiceType _getRequiredCollaboratorType(ServiceType treatmentType) {
    if (treatmentType == ServiceType.combo) {
      return ServiceType.capelli;
    }
    return treatmentType;
  }

  // ===========================================
  // CARICAMENTO DATI
  // ===========================================

  Future<void> _fetchBusinessClosures() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('business_closures').get();
      if (mounted) {
        setState(() {
          _closureDays = snapshot.docs.map((doc) {
            final date = (doc.data()['date'] as Timestamp).toDate();
            return DateTime(date.year, date.month, date.day);
          }).toList();
        });
      }
    } catch (e) {
      print("Errore caricamento chiusure: $e");
    }
  }

  Future<void> _fetchCollaborators() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('collaborators').get();
      if (mounted) {
        setState(() {
          _allCollaborators = snapshot.docs.map((doc) {
            final data = doc.data();
            return Collaborator.fromJson({...data, 'id': doc.id});
          }).toList();
          _isLoadingCollaborators = false;
        });
      }
    } catch (e) {
      print("Errore caricamento collaboratori: $e");
      if (mounted) setState(() => _isLoadingCollaborators = false);
    }
  }

  // 🟢 NUOVO: Funzione che ascolta in TEMPO REALE (snapshots) invece di una volta sola (get)
  void _listenToBookingsForDay(DateTime day) {
    setState(() => _isLoadingBookings = true);

    // Annulla l'ascolto precedente se cambiamo giorno
    _bookingsSubscription?.cancel();

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots() // <--- Qui sta la magia: ascolta le modifiche
        .listen(
          (snapshot) {
        if (mounted) {
          setState(() {
            _todaysBookings = snapshot.docs
                .map((doc) => Booking.fromJson(doc.data(), doc.id))
                .toList();
            _isLoadingBookings = false;
          });
          // Se il bottom sheet è aperto, forziamo un aggiornamento dell'interfaccia
          // Nota: StatefulBuilder nel foglio modale gestirà il ricarico se lo stato cambia
        }
      },
      onError: (e) {
        print("Errore stream bookings: $e");
        if (mounted) setState(() => _isLoadingBookings = false);
      },
    );
  }

  // ===========================================
  // LOGICA SLOT ORARI E DISPONIBILITÀ
  // ===========================================

  List<String> _generateTimeSlots(DateTime selectedDate, int treatmentDurationMinutes) {
    final List<String> potentialSlots = [];
    final intervals = BusinessHours.getWorkingIntervals(selectedDate);
    const int slotIntervalMinutes = 30;

    if (intervals.isEmpty) return [];

    for (final interval in intervals) {
      TimeOfDay startTime = interval['start']!;
      TimeOfDay endTime = interval['end']!;

      int currentMinute = startTime.hour * 60 + startTime.minute;
      int endMinute = endTime.hour * 60 + endTime.minute;

      while (currentMinute + treatmentDurationMinutes <= endMinute) {
        final slotTime = TimeOfDay(hour: currentMinute ~/ 60, minute: currentMinute % 60);

        final now = DateTime.now();
        final slotDateTime = DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day,
            slotTime.hour, slotTime.minute);

        if (!isSameDay(selectedDate, now) || slotDateTime.isAfter(now.add(const Duration(minutes: 15)))) {
          final formattedTimeString = '${slotTime.hour.toString().padLeft(2, '0')}${slotTime.minute.toString().padLeft(2, '0')}';
          potentialSlots.add(formattedTimeString);
        }

        currentMinute += slotIntervalMinutes;
      }
    }
    return potentialSlots.toSet().toList()..sort();
  }

  bool isCollaboratorAvailable(Collaborator collaborator, String timeHHmm, Treatment? treatment) {
    if (collaborator.isDisabled) return false;
    if (treatment == null) return true;

    final int startHour = int.parse(timeHHmm.substring(0, 2));
    final int startMinute = int.parse(timeHHmm.substring(2, 4));

    final day = _selectedDay ?? DateTime.now();
    final newBookingStart = DateTime(day.year, day.month, day.day, startHour, startMinute);
    final newBookingEnd = newBookingStart.add(Duration(minutes: treatment.durationInMinutes));

    // 1. Controllo Turni Settimanali
    final int weekday = newBookingStart.weekday;
    final List<String>? daySlots = collaborator.availability[weekday];

    if (daySlots == null || daySlots.isEmpty) {
      return false;
    }

    DateTime checkTime = newBookingStart;
    while (checkTime.isBefore(newBookingEnd)) {
      final checkTimeString = '${checkTime.hour.toString().padLeft(2, '0')}${checkTime.minute.toString().padLeft(2, '0')}';
      if (!daySlots.contains(checkTimeString)) {
        return false;
      }
      checkTime = checkTime.add(const Duration(minutes: 30));
    }

    // 2. Controllo Assenze Specifche
    if (collaborator.specificAbsences != null) {
      for (final absence in collaborator.specificAbsences!) {
        final absenceDate = DateTime(absence.date.year, absence.date.month, absence.date.day);

        if (isSameDay(absenceDate, newBookingStart)) {
          final startParts = absence.startTime.split(':');
          final endParts = absence.endTime.split(':');

          final absStart = DateTime(day.year, day.month, day.day, int.parse(startParts[0]), int.parse(startParts[1]));
          final absEnd = DateTime(day.year, day.month, day.day, int.parse(endParts[0]), int.parse(endParts[1]));

          if (newBookingStart.isBefore(absEnd) && newBookingEnd.isAfter(absStart)) {
            return false;
          }
        }
      }
    }

    // 3. Controllo Sovrapposizione Prenotazioni (CRITICO PER IL TUO PROBLEMA)
    // Ora _todaysBookings è aggiornato in tempo reale grazie allo stream
    for (final existingBooking in _todaysBookings) {
      // Controlliamo se la prenotazione appartiene allo stesso collaboratore
      if (existingBooking.collaborator.id == collaborator.id) {

        final existingStart = existingBooking.date;
        final existingEnd = existingStart.add(Duration(minutes: existingBooking.treatment.durationInMinutes));

        // Logica di sovrapposizione:
        // La nuova inizia PRIMA che la vecchia finisca E la nuova finisce DOPO che la vecchia inizi
        if (newBookingStart.isBefore(existingEnd) && newBookingEnd.isAfter(existingStart)) {
          return false; // OCCUPATO
        }
      }
    }

    return true; // LIBERO
  }

  // ===========================================
  // UI & INTERAZIONE
  // ===========================================

  bool _isDayClosed(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final isClosedByFirestore = _closureDays.any((d) => isSameDay(d, normalizedDay));
    final isClosedByBusinessHours = BusinessHours.getWorkingIntervals(normalizedDay).isEmpty;
    return isClosedByFirestore || isClosedByBusinessHours;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_isDayClosed(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Il salone è chiuso in questa data.'), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // 🟢 NUOVO: Aggiorna lo stream sul nuovo giorno selezionato
    _listenToBookingsForDay(selectedDay);

    if (mounted) _showBookingSheet(selectedDay);
  }

  void _showBookingSheet(DateTime day) {
    Treatment? selectedTreatmentInSheet;
    if (widget.initialTreatment != null) {
      try {
        selectedTreatmentInSheet = widget.treatments.firstWhere((t) => t.name == widget.initialTreatment!.name);
      } catch (_) {}
    }

    String? selectedTimeInSheet;
    Collaborator? selectedCollaboratorInSheet;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {

            List<String> generatedTimeSlots = [];
            if (selectedTreatmentInSheet != null) {
              generatedTimeSlots = _generateTimeSlots(day, selectedTreatmentInSheet!.durationInMinutes);
            }

            List<Collaborator> filteredCollaborators = [];
            if (selectedTreatmentInSheet != null) {
              final requiredType = _getRequiredCollaboratorType(selectedTreatmentInSheet!.type);
              filteredCollaborators = _allCollaborators.where((c) {
                final typesMatch = c.assignedServiceTypes.any((t) => t == requiredType);
                return typesMatch;
              }).toList();
            }

            final bool isButtonActive = selectedTreatmentInSheet != null &&
                selectedTimeInSheet != null &&
                selectedCollaboratorInSheet != null;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                top: 24, left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text('Prenota per il ${DateFormat('dd/MM/yyyy').format(day)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  // SELEZIONE TRATTAMENTO
                  DropdownButtonFormField<Treatment>(
                    value: selectedTreatmentInSheet,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Trattamento',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: widget.treatments.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text("${t.name} (${t.durationInMinutes} min)", overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) {
                      sheetSetState(() {
                        selectedTreatmentInSheet = val;
                        selectedTimeInSheet = null;
                        selectedCollaboratorInSheet = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // SELEZIONE ORARIO
                  if (selectedTreatmentInSheet != null) ...[
                    Text("Scegli Orario", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    generatedTimeSlots.isEmpty
                        ? const Text("Nessun orario disponibile.", style: TextStyle(color: Colors.red))
                        : Wrap(
                      spacing: 8, runSpacing: 8,
                      children: generatedTimeSlots.map((time) {
                        return ChoiceChip(
                          label: Text("${time.substring(0,2)}:${time.substring(2,4)}"),
                          selected: selectedTimeInSheet == time,
                          onSelected: (sel) {
                            sheetSetState(() {
                              selectedTimeInSheet = sel ? time : null;
                              selectedCollaboratorInSheet = null;
                            });
                          },
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(color: selectedTimeInSheet == time ? Colors.white : Colors.black),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SELEZIONE COLLABORATORE
                  if (selectedTimeInSheet != null && selectedTreatmentInSheet != null) ...[
                    Text("Scegli Professionista", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    filteredCollaborators.isEmpty
                        ? const Text("Nessuno staff disponibile per questo servizio.", style: TextStyle(color: Colors.red))
                        : Wrap(
                      spacing: 8, runSpacing: 8,
                      children: filteredCollaborators.map((c) {
                        // Qui chiama la funzione che controlla lo Stream aggiornato
                        final isAvailable = isCollaboratorAvailable(c, selectedTimeInSheet!, selectedTreatmentInSheet);

                        return ChoiceChip(
                          label: Text(c.name),
                          selected: selectedCollaboratorInSheet?.id == c.id,
                          selectedColor: primaryColor,
                          backgroundColor: isAvailable ? null : Colors.grey.shade200,
                          labelStyle: TextStyle(
                              color: selectedCollaboratorInSheet?.id == c.id ? Colors.white : (isAvailable ? Colors.black : Colors.grey),
                              decoration: isAvailable ? null : TextDecoration.lineThrough
                          ),
                          onSelected: isAvailable ? (sel) {
                            sheetSetState(() => selectedCollaboratorInSheet = sel ? c : null);
                          } : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // BOTTONE CONFERMA
                  ElevatedButton(
                    onPressed: isButtonActive ? () {
                      final startH = int.parse(selectedTimeInSheet!.substring(0,2));
                      final startM = int.parse(selectedTimeInSheet!.substring(2,4));

                      final newBooking = Booking(
                        treatment: selectedTreatmentInSheet!,
                        date: DateTime(day.year, day.month, day.day, startH, startM),
                        time: selectedTimeInSheet!,
                        collaborator: selectedCollaboratorInSheet!,
                        userId: '',
                        userName: '',
                      );
                      Navigator.pop(sheetContext, newBooking);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Conferma Prenotazione", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is Booking) {
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCollaborators) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitle), backgroundColor: primaryColor, foregroundColor: Colors.white),
      body: Column(
        children: [
          TableCalendar(
            locale: 'it_IT',
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: primaryColor.withOpacity(0.5), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            enabledDayPredicate: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              if (normalizedDay.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
                return false;
              }
              if (_isDayClosed(normalizedDay)) return false;
              return true;
            },
            calendarBuilders: CalendarBuilders(
              disabledBuilder: (context, day, focusedDay) {
                if (_isDayClosed(day)) {
                  if (!day.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                            color: Colors.red.withOpacity(0.6),
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    );
                  }
                }
                return null;
              },
            ),
          ),
          const Divider(),
          if (_isLoadingBookings) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Seleziona una data per vedere le disponibilità.", style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}