import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


enum ServiceType {
  capelli,
  unghie,
  Speciali, // Servizi che richiedono una chiamata/consulenza specifica
}

// ----------------------------------------------------------------------
// CLASSE: Treatment
// Rappresenta un singolo trattamento offerto (es. "Messa in piega", "Manicure Classica").
// ----------------------------------------------------------------------
class Treatment {
  final String name;
  final double price;
  final ServiceType type; // Il tipo di servizio a cui appartiene questo trattamento
  final int durationInMinutes;

  const Treatment({
    required this.name,
    required this.price,
    required this.type,
    required this.durationInMinutes,
  });

  // Converte un oggetto Treatment in un Map per il salvataggio su Firestore.
  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'type': type.toString().split('.').last, // Salva solo il nome dell'enum come stringa (es. 'capelli')
    'durationInMinutes': durationInMinutes,
  };

  // Factory per creare un oggetto Treatment da un Map (tipicamente da Firestore/JSON).
  factory Treatment.fromJson(Map<String, dynamic> json) => Treatment(
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(), // Gestisce sia int che double per il prezzo
    type: ServiceType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
      orElse: () => ServiceType.capelli, // Fallback sicuro se il tipo non viene trovato (evita "No element")
    ),
    durationInMinutes: (json['durationInMinutes'] as int?) ?? 0,
  );
}

// ----------------------------------------------------------------------
// CLASSE: Collaborator
// Rappresenta un operatore/specialista del salone.
// ----------------------------------------------------------------------
class Collaborator {
  final String id; // L'ID univoco del collaboratore (es. ID documento Firestore)
  final String name;
  // `type` rappresenta il tipo di servizio principale/predefinito del collaboratore.
  final ServiceType type;
  // `assignedServiceTypes` è una lista dei tipi di servizio che il collaboratore può effettivamente gestire.
  // Utile per filtri e per mostrare la sua versatilità.
  final List<ServiceType> assignedServiceTypes;

  const Collaborator({
    required this.id,
    required this.name,
    required this.type,
    this.assignedServiceTypes = const [], // Default a lista vuota se non specificato
  });

  // Converte un oggetto Collaborator in un Map per il salvataggio su Firestore.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'assignedServiceTypes': assignedServiceTypes.map((e) => e.toString().split('.').last).toList(),
  };

  // Factory per creare un oggetto Collaborator da un Map (tipicamente da Firestore/JSON).
  factory Collaborator.fromJson(Map<String, dynamic> json) => Collaborator(
    id: json['id'] as String,
    name: json['name'] as String,
    type: ServiceType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
      orElse: () => ServiceType.capelli, // Fallback sicuro
    ),
    assignedServiceTypes: (json['assignedServiceTypes'] as List? ?? [])
        .map((e) => ServiceType.values.firstWhere(
          (enumType) => enumType.toString().split('.').last == e,
      orElse: () => ServiceType.capelli, // Fallback sicuro per ogni elemento della lista
    ))
        .toList(),
  );
}

// ----------------------------------------------------------------------
// CLASSE: Booking
// Rappresenta una prenotazione effettuata da un utente.
// ----------------------------------------------------------------------
class Booking {
  final String? id; // L'ID del documento Firestore, può essere null quando si crea la prenotazione localmente.
  final Treatment treatment;
  final DateTime date; // Data della prenotazione
  final String time; // Orario della prenotazione in formato stringa (es. "10:00")
  final Collaborator collaborator;
  final String userId; // L'ID dell'utente che ha effettuato la prenotazione
  final String? userName; // ✅ AGGIUNTO: Nome dell'utente (opzionale, utile per la visualizzazione)

  const Booking({
    this.id, // ID opzionale nel costruttore
    required this.treatment,
    required this.date,
    required this.time,
    required this.collaborator,
    required this.userId,
    this.userName, // ✅ AGGIUNTO AL COSTRUTTORE
  });

  // Converte un oggetto Booking in un Map per il salvataggio su Firestore.
  Map<String, dynamic> toJson() => {
    'treatment': treatment.toJson(),
    'date': Timestamp.fromDate(date), // Converte DateTime in Firestore Timestamp
    'time': time,
    'collaborator': collaborator.toJson(),
    'userId': userId,
    'userName': userName, // ✅ AGGIUNTO AL toJSON
  };

  // Factory per creare un oggetto Booking da un Map (doc.data()) e l'ID del documento Firestore.
  factory Booking.fromJson(Map<String, dynamic> json, String id) => Booking(
    id: id, // Assegna l'ID del documento Firestore
    userId: json['userId'] as String,
    treatment: Treatment.fromJson(json['treatment'] as Map<String, dynamic>),
    date: (json['date'] as Timestamp).toDate(), // Converte Firestore Timestamp in DateTime
    time: json['time'] as String,
    collaborator: Collaborator.fromJson(json['collaborator'] as Map<String, dynamic>),
    userName: json['userName'] as String?, // ✅ AGGIUNTO AL fromJSON (come stringa opzionale)
  );
}