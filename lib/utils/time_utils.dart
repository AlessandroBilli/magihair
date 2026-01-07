// lib/utils/time_utils.dart
// Centralizza la normalizzazione/parsing dell'orario in "HHmm".

String normalizeToHHmm(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return "";
  final padded = digits.padLeft(4, '0');
  return padded.length > 4 ? padded.substring(0, 4) : padded;
}

/// Converte "HHmm" in DateTime sul giorno base fornito.
DateTime hhmmToDateTime(String hhmm, DateTime baseDay) {
  final n = normalizeToHHmm(hhmm);
  final hour = int.tryParse(n.substring(0,2)) ?? 0;
  final minute = int.tryParse(n.substring(2,4)) ?? 0;
  return DateTime(baseDay.year, baseDay.month, baseDay.day, hour, minute);
}

/// Converte DateTime -> "HHmm"
String formatDateTimeToHHmm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2,'0');
  final m = dt.minute.toString().padLeft(2,'0');
  return '$h$m';
}

/// Rende "HHmm" più leggibile "HH:mm"
String hhmmToHuman(String hhmm) {
  final n = normalizeToHHmm(hhmm);
  return '${n.substring(0,2)}:${n.substring(2,4)}';
}
