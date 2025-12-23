import 'package:intl/intl.dart';

class Formatters {
  static String distance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  static String duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  static String durationText(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk ${secs}sn';
    }
    if (minutes > 0) {
      return '${minutes}dk ${secs}sn';
    }
    return '${secs}sn';
  }

  // Convert m/s to km/h
  static String speed(double metersPerSecond) {
    final kmh = metersPerSecond * 3.6;
    return '${kmh.toStringAsFixed(1)} km/s';
  }

  static String date(DateTime dateTime) {
    return DateFormat('dd MMM yyyy', 'tr_TR').format(dateTime);
  }

  static String time(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(dateTime);
  }

  static String coordinate(double value, {int decimals = 6}) {
    return value.toStringAsFixed(decimals);
  }

  static String number(num value) {
    return NumberFormat('#,##0', 'tr_TR').format(value);
  }
}
