import 'package:cloud_firestore/cloud_firestore.dart';

// ENUM: Tipi di Servizio
enum ServiceType {
  capelli,
  unghie,
  combo,
  Speciali, // Servizi che richiedono una chiamata/consulenza specifica
}

// =============================
// CLASSE: CollaboratorAbsence
// =============================
class CollaboratorAbsence {
  final DateTime date;
  final String startTime; // Formato HH:mm
  final String endTime;   // Formato HH:mm

  const CollaboratorAbsence({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory CollaboratorAbsence.fromJson(Map<String, dynamic> json) {
    return CollaboratorAbsence(
      date: (json['date'] as Timestamp).toDate(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }
}

// =============================
// CLASSE: Treatment
// =============================
class Treatment {
  final String name;
  final double price;
  final ServiceType type;
  final int durationInMinutes;

  const Treatment({
    required this.name,
    required this.price,
    required this.type,
    required this.durationInMinutes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Treatment &&
        other.name == name &&
        other.price == price &&
        other.type == type &&
        other.durationInMinutes == durationInMinutes;
  }

  @override
  int get hashCode =>
      name.hashCode ^ price.hashCode ^ type.hashCode ^ durationInMinutes.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'type': type.toString().split('.').last,
      'durationInMinutes': durationInMinutes,
    };
  }

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      type: ServiceType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => ServiceType.capelli,
      ),
      durationInMinutes: (json['durationInMinutes'] as int?) ?? 0,
    );
  }
}

// =============================
// CLASSE: Collaborator
// =============================
class Collaborator {
  final String id;
  final String name;
  final ServiceType type; // Ruolo principale
  final List<ServiceType> assignedServiceTypes; // Servizi che può eseguire
  // Mappa: Chiave INT (1=Lun, 7=Dom), Valore List<String> 'HHmm'
  final Map<int, List<String>> availability;
  final bool isDisabled;
  final List<CollaboratorAbsence>? specificAbsences;

  const Collaborator({
    required this.id,
    required this.name,
    required this.type,
    this.assignedServiceTypes = const [],
    this.availability = const {},
    this.isDisabled = false,
    this.specificAbsences,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonAvailability = {};
    // Convertiamo le chiavi int in stringhe per Firestore ('1', '2'...)
    availability.forEach((key, value) {
      jsonAvailability[key.toString()] = value;
    });

    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'assignedServiceTypes': assignedServiceTypes
          .map((e) => e.toString().split('.').last)
          .toList(),
      'availability': jsonAvailability,
      'isDisabled': isDisabled,
      'specificAbsences': specificAbsences?.map((a) => a.toJson()).toList(),
    };
  }

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    Map<int, List<String>> parsedAvailability = {};

    // Parsing robusto della disponibilità
    if (json['availability'] is Map) {
      (json['availability'] as Map<dynamic, dynamic>).forEach((key, value) {
        final int? dayKey = int.tryParse(key.toString());
        if (dayKey != null && dayKey > 0 && dayKey <= 7 && value is List) {
          final List<String> stringSlots =
          (value as List).map((e) => e.toString()).toList();
          parsedAvailability[dayKey] = stringSlots;
        }
      });
    }

    List<CollaboratorAbsence>? absences;
    if (json['specificAbsences'] is List) {
      absences = (json['specificAbsences'] as List)
          .map((a) => CollaboratorAbsence.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return Collaborator(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Nome sconosciuto',
      type: ServiceType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => ServiceType.capelli,
      ),
      assignedServiceTypes: (json['assignedServiceTypes'] as List? ?? [])
          .map((e) => ServiceType.values.firstWhere(
            (enumType) => enumType.toString().split('.').last == e,
        orElse: () => ServiceType.capelli,
      ))
          .toList(),
      isDisabled: json['isDisabled'] ?? false,
      availability: parsedAvailability,
      specificAbsences: absences,
    );
  }

  // Metodo copyWith utile per modifiche parziali
  Collaborator copyWith({
    String? id,
    String? name,
    ServiceType? type,
    List<ServiceType>? assignedServiceTypes,
    Map<int, List<String>>? availability,
    bool? isDisabled,
    List<CollaboratorAbsence>? specificAbsences,
  }) {
    return Collaborator(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      assignedServiceTypes: assignedServiceTypes ?? this.assignedServiceTypes,
      availability: availability ?? this.availability,
      isDisabled: isDisabled ?? this.isDisabled,
      specificAbsences: specificAbsences ?? this.specificAbsences,
    );
  }
}

// =============================
// CLASSE: Booking
// =============================
class Booking {
  final String? id;
  final Treatment treatment;
  final DateTime date;
  final String time; // HHmm
  final Collaborator collaborator;
  final String userId;
  final String? userName;

  const Booking({
    this.id,
    required this.treatment,
    required this.date,
    required this.time,
    required this.collaborator,
    required this.userId,
    this.userName,
  });

  Map<String, dynamic> toJson() {
    return {
      'treatment': treatment.toJson(),
      'date': Timestamp.fromDate(date),
      'time': time,
      'collaborator': collaborator.toJson(),
      'userId': userId,
      'userName': userName,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json, String id) {
    return Booking(
      id: id,
      userId: json['userId'] as String? ?? '',
      treatment: Treatment.fromJson(json['treatment'] as Map<String, dynamic>),
      date: (json['date'] as Timestamp).toDate(),
      time: json['time'] as String,
      collaborator:
      Collaborator.fromJson(json['collaborator'] as Map<String, dynamic>),
      userName: json['userName'] as String?,
    );
  }
}

// =============================
// CLASSE: BusinessClosure
// =============================
class BusinessClosure {
  final String id;
  final DateTime date;
  final String reason;

  const BusinessClosure({
    required this.id,
    required this.date,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'reason': reason,
    };
  }

  // Aggiungiamo un factory se serve recuperarlo da Firestore
  factory BusinessClosure.fromJson(Map<String, dynamic> json, String id) {
    return BusinessClosure(
      id: id,
      date: (json['date'] as Timestamp).toDate(),
      reason: json['reason'] as String? ?? '',
    );
  }
}