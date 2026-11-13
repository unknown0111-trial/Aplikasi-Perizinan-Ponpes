import 'enums.dart';

/// Format tanggal untuk database (yyyy-MM-dd).
String toDbDate(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

class Perizinan {
  final int? id;
  final int userId;
  final JenisIzin jenis;
  final DateTime tanggalPengajuan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String? jamKeluar; // "HH:mm"
  final String? jamKembali; // "HH:mm"
  final String? tujuan;
  final String? penjemput;
  final String? keluhan;
  final String alasan;
  final String? keterangan;
  final StatusIzin status;
  final int? diprosesOleh;
  final String? catatanPengurus;
  final DateTime? tanggalDiproses;

  // Hasil join dengan tabel users (tidak disimpan di tabel perizinan).
  final String namaPemohon;
  final String noIdentitasPemohon;
  final int levelPemohon;
  final String? namaPemroses;

  const Perizinan({
    this.id,
    required this.userId,
    required this.jenis,
    required this.tanggalPengajuan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.jamKeluar,
    this.jamKembali,
    this.tujuan,
    this.penjemput,
    this.keluhan,
    required this.alasan,
    this.keterangan,
    this.status = StatusIzin.menunggu,
    this.diprosesOleh,
    this.catatanPengurus,
    this.tanggalDiproses,
    this.namaPemohon = '',
    this.noIdentitasPemohon = '',
    this.levelPemohon = 0,
    this.namaPemroses,
  });

  factory Perizinan.fromMap(Map<String, Object?> m) => Perizinan(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    jenis: JenisIzin.values.byName(m['jenis'] as String),
    tanggalPengajuan: DateTime.parse(m['tanggal_pengajuan'] as String),
    tanggalMulai: DateTime.parse(m['tanggal_mulai'] as String),
    tanggalSelesai: DateTime.parse(m['tanggal_selesai'] as String),
    jamKeluar: m['jam_keluar'] as String?,
    jamKembali: m['jam_kembali'] as String?,
    tujuan: m['tujuan'] as String?,
    penjemput: m['penjemput'] as String?,
    keluhan: m['keluhan'] as String?,
    alasan: m['alasan'] as String,
    keterangan: m['keterangan'] as String?,
    status: StatusIzin.values.byName(m['status'] as String),
    diprosesOleh: m['diproses_oleh'] as int?,
    catatanPengurus: m['catatan_pengurus'] as String?,
    tanggalDiproses: m['tanggal_diproses'] == null
        ? null
        : DateTime.parse(m['tanggal_diproses'] as String),
    namaPemohon: (m['nama_pemohon'] as String?) ?? '',
    noIdentitasPemohon: (m['no_identitas_pemohon'] as String?) ?? '',
    levelPemohon: (m['level_pemohon'] as int?) ?? 0,
    namaPemroses: m['nama_pemroses'] as String?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'jenis': jenis.name,
    'tanggal_pengajuan': toDbDate(tanggalPengajuan),
    'tanggal_mulai': toDbDate(tanggalMulai),
    'tanggal_selesai': toDbDate(tanggalSelesai),
    'jam_keluar': jamKeluar,
    'jam_kembali': jamKembali,
    'tujuan': tujuan,
    'penjemput': penjemput,
    'keluhan': keluhan,
    'alasan': alasan.trim(),
    'keterangan': keterangan?.trim(),
    'status': status.name,
    'diproses_oleh': diprosesOleh,
    'catatan_pengurus': catatanPengurus,
    'tanggal_diproses': tanggalDiproses?.toIso8601String(),
  };
}
