import 'package:intl/intl.dart';

/// Memerlukan initializeDateFormatting('id_ID') di main().
class Fmt {
  static final _tgl = DateFormat('d MMM yyyy', 'id_ID');
  static final _hari = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  static final _tglJam = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
  static String tanggalJam(DateTime d) => _tglJam.format(d);

  static String tanggal(DateTime d) => _tgl.format(d);
  static String hariLengkap(DateTime d) => _hari.format(d);

  static String rentang(DateTime a, DateTime b) {
    final sama = a.year == b.year && a.month == b.month && a.day == b.day;
    return sama ? tanggal(a) : '${tanggal(a)} – ${tanggal(b)}';
  }
}
