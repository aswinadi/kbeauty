import 'package:intl/intl.dart';

/// Centralised date/time helper.
///
/// The backend stores all timestamps in UTC.  The app targets WIB (UTC+7), so
/// every timestamp that comes from the server must be shifted before display.
///
/// Usage:
///   DateHelper.formatDateTime('2026-06-02T05:38:00.000000Z')
///   // → '02 Jun 2026, 12:38'
class DateHelper {
  static const Duration _wib = Duration(hours: 7);

  /// Parse a UTC ISO-8601 string and convert it to WIB (UTC+7).
  static DateTime toWib(String utcString) {
    // DateTime.parse handles both "...Z" and "...+00:00" formats.
    // isUtc will be true for the "Z" suffix; we normalise via toUtc() anyway.
    final dt = DateTime.parse(utcString);
    return dt.isUtc ? dt.add(_wib) : dt.toUtc().add(_wib);
  }

  /// '02 Jun 2026, 12:38'
  static String formatDateTime(String? utcString) {
    if (utcString == null || utcString.isEmpty) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(toWib(utcString));
  }

  /// '02/06/2026 12:38'  (used in receipts)
  static String formatDateTimeReceipt(String? utcString) {
    if (utcString == null || utcString.isEmpty) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(toWib(utcString));
  }

  /// '02 Jun 2026'  (date-only, no time)
  static String formatDate(String? utcString) {
    if (utcString == null || utcString.isEmpty) return '-';
    return DateFormat('dd MMM yyyy').format(toWib(utcString));
  }

  /// Returns just 'yyyy-MM-dd' portion in WIB — used in the history card header.
  static String formatDateShort(String? utcString) {
    if (utcString == null || utcString.isEmpty) return '-';
    return DateFormat('yyyy-MM-dd').format(toWib(utcString));
  }
}
