import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Collaborator> _allCollaborators = [];
  List<BusinessClosure> _allClosures = [];
  List<Booking> _allBookings = []; // 🟢 NUOVO: Lista prenotazioni
  bool _isLoading = true;

  final List<String> _validTimes = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '12:00', '12:30',
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00'
  ];

  final Map<int, String> _italianDayNames = {
    1: 'Lunedì', 2: 'Martedì', 3: 'Mercoledì', 4: 'Giovedì',
    5: 'Venerdì', 6: 'Sabato', 7: 'Domenica',
  };

  @override
  void initState() {
    super.initState();
    // 🟢 MODIFICA: 3 Tab: Staff, Prenotazioni, Chiusure
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final cSnap = await FirebaseFirestore.instance.collection('collaborators').get();
      final clSnap = await FirebaseFirestore.instance.collection('business_closures').orderBy('date').get();

      // 🟢 NUOVO: Caricamento prenotazioni (ordinate per data decrescente)
      final bSnap = await FirebaseFirestore.instance.collection('bookings').orderBy('date', descending: true).get();

      if (mounted) {
        setState(() {
          _allCollaborators = cSnap.docs.map((d) => Collaborator.fromJson({...d.data(), 'id': d.id})).toList();

          _allClosures = clSnap.docs.map((d) {
            final data = d.data();
            return BusinessClosure(
              id: d.id,
              date: (data['date'] as Timestamp).toDate(),
              reason: data['reason'] ?? '',
            );
          }).toList();
          // Filtriamo chiusure vecchie per pulizia
          _allClosures = _allClosures.where((c) => c.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

          // Mappatura prenotazioni
          _allBookings = bSnap.docs.map((d) => Booking.fromJson(d.data(), d.id)).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Errore caricamento admin: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCollaboratorStatus(Collaborator c, bool newStatus) async {
    await FirebaseFirestore.instance.collection('collaborators').doc(c.id).update({
      'isDisabled': newStatus
    });
    _loadAdminData();
  }

  Future<void> _deleteClosure(String id) async {
    await FirebaseFirestore.instance.collection('business_closures').doc(id).delete();
    _loadAdminData();
  }

  // 🟢 NUOVO: Cancellazione prenotazione
  Future<void> _deleteBooking(Booking booking) async {
    bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Cancella Prenotazione"),
          content: Text("Vuoi cancellare la prenotazione di ${booking.userName}?"),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("No")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: ()=>Navigator.pop(ctx, true),
                child: const Text("Sì, Cancella")
            )
          ],
        )
    ) ?? false;

    if(confirm && booking.id != null) {
      await FirebaseFirestore.instance.collection('bookings').doc(booking.id).delete();
      _loadAdminData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prenotazione cancellata.")));
    }
  }

  // ============================================
  // LOGICA ORARI STAFF
  // ============================================
  List<String> _generateSlots(String startHHMM, String endHHMM) {
    if (startHHMM.isEmpty || endHHMM.isEmpty) return [];
    int startIndex = _validTimes.indexOf(startHHMM);
    int endIndex = _validTimes.indexOf(endHHMM);
    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) return [];
    return _validTimes.sublist(startIndex, endIndex).map((t) => t.replaceAll(':', '')).toList();
  }

  String toTimeFormat(String hhmm) {
    if (hhmm.length < 4) return hhmm;
    return '${hhmm.substring(0, 2)}:${hhmm.substring(2, 4)}';
  }

  void _showAvailabilityDialog(Collaborator collaborator) {
    final Map<int, String?> startTimes = {};
    final Map<int, String?> endTimes = {};
    collaborator.availability.forEach((day, slots) {
      if (slots.isNotEmpty) {
        startTimes[day] = toTimeFormat(slots.first);
        String lastSlot = toTimeFormat(slots.last);
        int idx = _validTimes.indexOf(lastSlot);
        if (idx != -1 && idx + 1 < _validTimes.length) endTimes[day] = _validTimes[idx + 1];
        else endTimes[day] = lastSlot;
      }
    });

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text('Orari per ${collaborator.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 7,
              itemBuilder: (context, index) {
                int day = index + 1;
                return Column(
                  children: [
                    Text(_italianDayNames[day]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(children: [
                      Expanded(child: DropdownButton<String>(hint: const Text("Inizio"), value: startTimes[day], isExpanded: true, items: _validTimes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (val) => setStateDialog(() { startTimes[day] = val; endTimes[day] = null; }))),
                      const SizedBox(width: 10),
                      Expanded(child: DropdownButton<String>(hint: const Text("Fine"), value: endTimes[day], isExpanded: true, items: _validTimes.where((t) { if (startTimes[day] == null) return false; return _validTimes.indexOf(t) > _validTimes.indexOf(startTimes[day]!); }).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (val) => setStateDialog(() => endTimes[day] = val))),
                      IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: () => setStateDialog(() { startTimes.remove(day); endTimes.remove(day); }))
                    ]),
                    const Divider()
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
            ElevatedButton(onPressed: () async {
              Map<String, List<String>> newAvailability = {};
              for (int day = 1; day <= 7; day++) {
                if (startTimes[day] != null && endTimes[day] != null) {
                  List<String> slots = _generateSlots(startTimes[day]!, endTimes[day]!);
                  newAvailability[day.toString()] = slots;
                }
              }
              await FirebaseFirestore.instance.collection('collaborators').doc(collaborator.id).update({'availability': newAvailability});
              _loadAdminData();
              Navigator.pop(context);
            }, child: const Text("Salva"))
          ],
        );
      });
    });
  }

  // ============================================
  // DIALOGHI (Chiusure e Staff)
  // ============================================
  void _showClosureDialog() {
    bool isRange = false;
    DateTime? singleDate;
    DateTimeRange? dateRange;
    final TextEditingController reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Nuova Chiusura"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isRange ? "Periodo (Ferie)" : "Giorno Singolo", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: isRange,
                        onChanged: (val) {
                          setStateDialog(() {
                            isRange = val;
                            singleDate = null;
                            dateRange = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      if (isRange) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('it', 'IT'),
                        );
                        if (picked != null) setStateDialog(() => dateRange = picked);
                      } else {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('it', 'IT'),
                        );
                        if (picked != null) setStateDialog(() => singleDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isRange
                                ? (dateRange == null ? "Seleziona date..." : "${DateFormat('dd/MM').format(dateRange!.start)} - ${DateFormat('dd/MM').format(dateRange!.end)}")
                                : (singleDate == null ? "Seleziona data..." : DateFormat('dd/MM/yyyy').format(singleDate!)),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.purple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Motivo (es. Ferie)")),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
                ElevatedButton(
                  onPressed: () async {
                    final reason = reasonCtrl.text.trim().isEmpty ? "Chiusura" : reasonCtrl.text.trim();
                    final firestore = FirebaseFirestore.instance;
                    final batch = firestore.batch();

                    if (isRange && dateRange != null) {
                      int days = dateRange!.end.difference(dateRange!.start).inDays;
                      for (int i = 0; i <= days; i++) {
                        DateTime dayToAdd = dateRange!.start.add(Duration(days: i));
                        DocumentReference docRef = firestore.collection('business_closures').doc();
                        batch.set(docRef, {
                          'date': Timestamp.fromDate(DateTime(dayToAdd.year, dayToAdd.month, dayToAdd.day)),
                          'reason': reason
                        });
                      }
                    } else if (!isRange && singleDate != null) {
                      DocumentReference docRef = firestore.collection('business_closures').doc();
                      batch.set(docRef, {
                        'date': Timestamp.fromDate(DateTime(singleDate!.year, singleDate!.month, singleDate!.day)),
                        'reason': reason
                      });
                    } else {
                      return;
                    }

                    await batch.commit();
                    _loadAdminData();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chiusura salvata!")));
                  },
                  child: const Text("Salva"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCollaboratorDialog({Collaborator? collaboratorToEdit}) {
    final TextEditingController nameCtrl = TextEditingController(text: collaboratorToEdit?.name ?? '');
    ServiceType selectedType = collaboratorToEdit?.type ?? ServiceType.capelli;
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(collaboratorToEdit == null ? "Nuovo Staff" : "Modifica Staff"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: "Nome",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.person, color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<ServiceType>(
                        value: selectedType,
                        decoration: InputDecoration(labelText: "Ruolo", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        items: ServiceType.values.where((t) => t != ServiceType.combo && t != ServiceType.Speciali).map((type) => DropdownMenuItem(value: type, child: Text(type.toString().split('.').last.toUpperCase()))).toList(),
                        onChanged: (val) { if (val != null) setStateDialog(() => selectedType = val); },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Annulla")),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        onPressed: () async {
                          if(nameCtrl.text.trim().isNotEmpty) {
                            final data = {
                              'name': nameCtrl.text.trim(),
                              'type': selectedType.toString().split('.').last,
                              'assignedServiceTypes': [selectedType.toString().split('.').last],
                            };
                            if(collaboratorToEdit == null) {
                              await FirebaseFirestore.instance.collection('collaborators').add({...data, 'isDisabled': false, 'availability': {}});
                            } else {
                              await FirebaseFirestore.instance.collection('collaborators').doc(collaboratorToEdit.id).update(data);
                            }
                            _loadAdminData();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Salva")
                    )
                  ],
                );
              }
          );
        }
    );
  }

  // ============================================
  // TAB BUILDERS
  // ============================================

  Widget _buildCollaboratorsTab() {
    final primaryColor = Theme.of(context).primaryColor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showCollaboratorDialog(),
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text("Aggiungi Collaboratore", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 20),
        ..._allCollaborators.map((c) {
          return Card(
            elevation: 4, margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: c.isDisabled ? BorderSide(color: Colors.red.shade200, width: 1.5) : BorderSide.none),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 28, backgroundColor: c.isDisabled ? Colors.grey.shade200 : primaryColor.withOpacity(0.1), child: Icon(c.isDisabled ? Icons.person_off : Icons.person, color: c.isDisabled ? Colors.grey : primaryColor, size: 30)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.isDisabled ? Colors.grey : Colors.black87, decoration: c.isDisabled ? TextDecoration.lineThrough : null)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: c.isDisabled ? Colors.grey.shade200 : primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(c.type.toString().split('.').last.toUpperCase(), style: TextStyle(fontSize: 10, color: c.isDisabled ? Colors.grey : primaryColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Switch(value: !c.isDisabled, activeColor: Colors.green, inactiveThumbColor: Colors.red, inactiveTrackColor: Colors.red.shade100, onChanged: (val) { _toggleCollaboratorStatus(c, !val); }),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _buildActionButton(Icons.edit, "Modifica", () => _showCollaboratorDialog(collaboratorToEdit: c)),
                    _buildActionButton(Icons.schedule, "Orari", () => _showAvailabilityDialog(c)),
                  ])
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildClosuresTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showClosureDialog(),
          icon: const Icon(Icons.event_busy, color: Colors.white),
          label: const Text("Aggiungi Chiusura / Ferie", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 20),
        if (_allClosures.isEmpty) const Center(child: Text("Nessuna chiusura programmata.", style: TextStyle(color: Colors.grey))),
        ..._allClosures.map((c) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: Icon(Icons.calendar_today, color: Colors.red.shade400)),
              title: Text(DateFormat('EEEE d MMMM yyyy', 'it_IT').format(c.date).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(c.reason, style: TextStyle(color: Colors.grey.shade600)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _deleteClosure(c.id),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // 🟢 NUOVO: UI per la Tab Prenotazioni
  Widget _buildBookingsTab() {
    if(_allBookings.isEmpty) {
      return const Center(child: Text("Nessuna prenotazione trovata.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allBookings.length,
      itemBuilder: (context, index) {
        final b = _allBookings[index];
        final isFuture = b.date.isAfter(DateTime.now());

        return Card(
          elevation: isFuture ? 4 : 1, // Meno enfasi sulle passate
          color: isFuture ? Colors.white : Colors.grey.shade100,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: isFuture ? Theme.of(context).primaryColor : Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE d MMMM yyyy - HH:mm', 'it_IT').format(b.date),
                        style: TextStyle(fontWeight: FontWeight.bold, color: isFuture ? Colors.black : Colors.grey),
                      ),
                    ),
                    if(isFuture)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBooking(b),
                      )
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(b.userName ?? "Cliente Sconosciuto", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.cut, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text("${b.treatment.name} (con ${b.collaborator.name})"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    final color = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestione Salone"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Staff"),
            // 🟢 REINSERITO: Tab Prenotazioni
            Tab(icon: Icon(Icons.calendar_month), text: "Prenotazioni"),
            Tab(icon: Icon(Icons.event_busy), text: "Chiusure"),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCollaboratorsTab(),
          _buildBookingsTab(), // 🟢 REINSERITO
          _buildClosuresTab(),
        ],
      ),
    );
  }
}