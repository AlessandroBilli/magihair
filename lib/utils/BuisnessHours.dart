// File: lib/utils/BusinessHours.dart (CONFIGURAZIONE FINALE E CORRETTA)

import 'package:flutter/material.dart';

class BusinessHours {
  // Orari di apertura per il salone. Le chiavi sono i giorni della settimana (1=Lunedì... 7=Domenica).
  // I valori sono liste di mappe che indicano gli intervalli di lavoro (start e end).
  static const Map<int, List<Map<String, TimeOfDay>>> hours = {

    // 1: Lunedì - CHIUSO
    1: [],

    // 2: Martedì: 09:00 – 13:00 E 15:30 – 19:00 (Pausa 13:00-15:30)
    2: [
      {'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 13, minute: 0)},
      {'start': TimeOfDay(hour: 15, minute: 30), 'end': TimeOfDay(hour: 19, minute: 0)},
    ],

    // 3: Mercoledì: 09:00 – 13:00 E 15:30 – 19:00 (Pausa 13:00-15:30)
    3: [
      {'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 13, minute: 0)},
      {'start': TimeOfDay(hour: 15, minute: 30), 'end': TimeOfDay(hour: 19, minute: 0)},
    ],

    // 4: Giovedì: 09:00 – 13:00 E 14:00 – 19:00 (Pausa 13:00-14:00)
    4: [
      {'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 13, minute: 0)},
      {'start': TimeOfDay(hour: 14, minute: 0), 'end': TimeOfDay(hour: 19, minute: 0)},
    ],

    // 5: Venerdì: 09:00 – 13:00 E 15:30 – 19:00 (Pausa 13:00-15:30)
    5: [
      {'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 13, minute: 0)},
      {'start': TimeOfDay(hour: 15, minute: 30), 'end': TimeOfDay(hour: 19, minute: 0)},
    ],

    // 6: Sabato: 09:00 – 18:00 (Orario unico)
    6: [
      {'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 18, minute: 0)},
    ],

    // 7: Domenica - CHIUSO
    7: [],
  };

  /// Restituisce la lista degli intervalli di lavoro (es. mattina e pomeriggio) per la data specificata.
  static List<Map<String, TimeOfDay>> getWorkingIntervals(DateTime date) {
    // DateTime.weekday restituisce 1 (Lunedì) a 7 (Domenica)
    return hours[date.weekday] ?? [];
  }
}