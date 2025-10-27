import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:magi_hair_off/core/models.dart';
import 'package:google_fonts/google_fonts.dart';

class CreaPrenotazioni extends StatefulWidget {
  final String pageTitle;
  final List<Treatment> treatments;
  final Treatment? initialTreatment;

  const CreaPrenotazioni({super.key, required this.pageTitle, required this.treatments,this.initialTreatment,});

  @override
  State<CreaPrenotazioni> createState() => _CreaPrenotazioniState();
}

class _CreaPrenotazioniState extends State<CreaPrenotazioni> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Booking> _todaysBookings = [];
  bool _isLoadingBookings = false;

  final List<Collaborator> _allCollaborators = const [
    // Reparto Capelli
    Collaborator(id: 'tania', name: 'Tania', type: ServiceType.capelli),
    Collaborator(id: 'mara', name: 'Mara', type: ServiceType.capelli),
    Collaborator(id: 'ludovica', name: 'Ludovica', type: ServiceType.capelli),

    // Reparto Onicotecnica
    Collaborator(id: 'giorgia', name: 'Giorgia', type: ServiceType.unghie),
    Collaborator(id: 'sandy', name: 'Sandy', type: ServiceType.unghie),
  ];
  Future<void> _fetchBookingsForDay(DateTime day) async {
    if (!mounted) return;
    setState(() => _isLoadingBookings = true);

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final bookings = snapshot.docs.map((doc) => Booking.fromJson(doc.data(), doc.id)).toList();

    if (mounted) {
      setState(() {
        _todaysBookings = bookings;
        _isLoadingBookings = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Non permettere di selezionare giorni passati
    if (selectedDay.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _fetchBookingsForDay(selectedDay).then((_) {
      _showBookingSheet(selectedDay);
    });
  }

  void _showBookingSheet(DateTime day) {
    Treatment? selectedTreatmentInSheet = widget.initialTreatment;
    String? selectedTimeInSheet;
    Collaborator? selectedCollaboratorInSheet;

    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter sheetSetState) {

            // ✅ NUOVA LOGICA: Filtra i collaboratori in base al tipo di trattamento selezionato
            final List<Collaborator> filteredCollaborators;
            if (selectedTreatmentInSheet != null) {
              filteredCollaborators = _allCollaborators.where((collaborator) =>
              collaborator.type == selectedTreatmentInSheet!.type
              ).toList();
            } else {
              filteredCollaborators = []; // Nessun trattamento selezionato, nessun collaboratore
            }

            // Logica per verificare la disponibilità del collaboratore (rimane invariata)
            bool isCollaboratorAvailable(Collaborator collaborator, String time, Treatment? treatment) {
              if (treatment == null) return true; // Non possiamo controllare senza la durata

              final newBookingStart = DateTime(day.year, day.month, day.day, int.parse(time.split(':')[0]), int.parse(time.split(':')[1]));
              final newBookingEnd = newBookingStart.add(Duration(minutes: treatment.durationInMinutes));

              for (final existingBooking in _todaysBookings) {
                if (existingBooking.collaborator.id == collaborator.id) {
                  final existingStart = existingBooking.date;
                  final existingEnd = existingStart.add(Duration(minutes: existingBooking.treatment.durationInMinutes));

                  // Controlla la sovrapposizione: (InizioA < FineB) e (FineA > InizioB)
                  if (newBookingStart.isBefore(existingEnd) && newBookingEnd.isAfter(existingStart)) {
                    return false; // Trovata sovrapposizione, non è disponibile
                  }
                }
              }
              return true; // Nessuna sovrapposizione, è disponibile
            }

            final isButtonActive = selectedTreatmentInSheet != null && selectedTimeInSheet != null && selectedCollaboratorInSheet != null;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24, left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Prenota per il ${DateFormat.yMMMMEEEEd('it_IT').format(day)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  // Dropdown per la selezione del trattamento
                  DropdownButtonFormField<Treatment>(
                    value: selectedTreatmentInSheet,
                    hint: const Text('Scegli un trattamento...'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    items: widget.treatments.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text("${t.name} (${t.durationInMinutes} min)", style: TextStyle(color: textColor)),
                    )).toList(),
                    onChanged: (value) => sheetSetState(() {
                      selectedTreatmentInSheet = value;
                      selectedCollaboratorInSheet = null; // Resetta il collaboratore se cambia trattamento
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Scelta dell'orario
                  Text('Scegli un orario:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'].map((time) => ChoiceChip(
                      label: Text(time),
                      selected: selectedTimeInSheet == time,
                      selectedColor: primaryColor,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(color: selectedTimeInSheet == time ? Colors.white : textColor),
                      onSelected: (isSelected) => sheetSetState(() {
                        if (isSelected) {
                          selectedTimeInSheet = time;
                          selectedCollaboratorInSheet = null; // Resetta il collaboratore se cambia orario
                        }
                      }),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Scelta del collaboratore (visibile solo dopo aver scelto orario e trattamento)
                  // ✅ MODIFICATO: Usa filteredCollaborators
                  if (selectedTimeInSheet != null && selectedTreatmentInSheet != null) ...[
                    Text('Scegli con chi:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8.0, runSpacing: 8.0,
                      children: filteredCollaborators.map((c) { // <-- Qui usiamo la lista filtrata
                        final available = isCollaboratorAvailable(c, selectedTimeInSheet!, selectedTreatmentInSheet);
                        return ChoiceChip(
                          label: Text(c.name),
                          selected: selectedCollaboratorInSheet?.id == c.id,
                          selectedColor: primaryColor,
                          backgroundColor: available ? Colors.grey.shade200 : Colors.grey.shade400,
                          labelStyle: TextStyle(
                            color: selectedCollaboratorInSheet?.id == c.id ? Colors.white : (available ? textColor : Colors.grey.shade600),
                            decoration: available ? TextDecoration.none : TextDecoration.lineThrough,
                          ),
                          onSelected: available ? (isSelected) => sheetSetState(() { if (isSelected) selectedCollaboratorInSheet = c; }) : null,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Pulsante di conferma prenotazione (rimane invariato)
                  ElevatedButton(
                    onPressed: isButtonActive ? () {
                      final newBooking = Booking(
                        treatment: selectedTreatmentInSheet!,
                        date: DateTime(day.year, day.month, day.day, int.parse(selectedTimeInSheet!.split(':')[0]), int.parse(selectedTimeInSheet!.split(':')[1])),
                        time: selectedTimeInSheet!,
                        collaborator: selectedCollaboratorInSheet!,
                        userId: '',
                      );
                      Navigator.pop(context, newBooking);
                    } : null,
                    child: const Text('Conferma Prenotazione'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    ).then((newBooking) {
      if (newBooking != null) {
        Navigator.pop(context, newBooking);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // La UI principale contiene solo il calendario.
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle), // Titolo dinamico (es. "Prenota Taglio Donna")
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              locale: 'it_IT',
              firstDay: DateTime.now(), // Il primo giorno selezionabile è oggi
              lastDay: DateTime.now().add(const Duration(days: 90)), // Fino a 90 giorni nel futuro
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day), // Seleziona il giorno
              onDaySelected: _onDaySelected,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration( // Stile per il giorno selezionato
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration( // Stile per il giorno corrente
                  color: primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                // Stile del testo dei giorni
                defaultTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                weekendTextStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
                outsideTextStyle: TextStyle(color: Colors.grey.shade400),
              ),
              headerStyle: HeaderStyle( // Stile dell'intestazione del calendario (mese e anno)
                titleCentered: true,
                formatButtonVisible: false, // Rimuove il bottone per cambiare formato
                titleTextStyle: Theme.of(context).textTheme.titleLarge!, // Font Lora
                leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
              ),
              daysOfWeekStyle: DaysOfWeekStyle( // Stile dei nomi dei giorni della settimana
                weekdayStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            if (_isLoadingBookings) // Mostra un indicatore di caricamento mentre si caricano le prenotazioni
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: primaryColor),
              ),
          ],
        ),
      ),
    );
  }
}

