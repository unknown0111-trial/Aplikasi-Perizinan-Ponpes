import 'package:sqflite/sqflite.dart';

import '../datasources/database_helper.dart';
import '../models/enums.dart';
import '../models/perizinan_model.dart';
import '../models/user_model.dart';

class PerizinanException implements Exception {
  final String message;
  PerizinanException(this.message);
  @override
  String toString() => message;
}

/// Aturan: siapa boleh memproses izin siapa.
class PerizinanRules {
  static bool bisaDiproses({
    required AppUser pemroses,
    required Perizinan izin,
  }) {
    if (!pemroses.isPengurus) return false;
    if (izin.status != StatusIzin.menunggu) return false;
    if (izin.userId == pemroses.id) {
      return false;
    }
    final level = pemroses.levelPengurus;
    return switch (izin.levelPemohon) {
      0 => level >= 1, // izin santri: pengurus mana pun
      1 => level >= 2, // izin pengurus: hanya pengurus senior
      _ => level >= 2, // izin pengurus senior: pengurus senior lain
    };
  }
}

class PerizinanRepository {
  PerizinanRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  static const _selectJoin = '''
    SELECT p.*,
           u.nama AS nama_pemohon,
           u.no_identitas AS no_identitas_pemohon,
           u.level_pengurus AS level_pemohon,
           pr.nama AS nama_pemroses
    FROM perizinan p
    JOIN users u ON u.id = p.user_id
    LEFT JOIN users pr ON pr.id = p.diproses_oleh
  ''';

  // ---------- CREATE ----------
  Future<int> create(Perizinan izin) async {
    _validate(izin);
    final db = await _dbHelper.database;
    await _pastikanTidakBentrok(db, izin);
    return db.transaction((txn) async {
      final id = await txn.insert('perizinan', izin.toMap());
      await _notifikasiPengajuanBaru(txn, izin, id);
      return id;
    });
  }

  /// Pemohon santri -> semua pengurus. Pemohon pengurus -> pengurus senior
  /// lain. Sama dengan aturan di [PerizinanRules].
  Future<void> _notifikasiPengajuanBaru(
    Transaction txn,
    Perizinan izin,
    int izinId,
  ) async {
    final rows = await txn.query(
      'users',
      where: 'id = ?',
      whereArgs: [izin.userId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final pemohon = rows.first;
    final level = (pemohon['level_pengurus'] as int?) ?? 0;
    final levelMinimal = level == 0 ? 1 : 2;

    final penerima = await txn.query(
      'users',
      columns: ['id'],
      where: "role = 'pengurus' AND level_pengurus >= ? AND id != ?",
      whereArgs: [levelMinimal, izin.userId],
    );
    final now = DateTime.now().toIso8601String();
    for (final p in penerima) {
      await txn.insert('notifikasi', {
        'user_id': p['id'],
        'perizinan_id': izinId,
        'judul': 'Pengajuan baru',
        'isi': '${pemohon['nama']} mengajukan ${izin.jenis.label}.',
        'dibaca': 0,
        'created_at': now,
      });
    }
  }

  // ---------- READ ----------
  Future<Perizinan?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('$_selectJoin WHERE p.id = ?', [id]);
    return rows.isEmpty ? null : Perizinan.fromMap(rows.first);
  }

  Future<List<Perizinan>> getByUser(int userId, {StatusIzin? status}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '$_selectJoin WHERE p.user_id = ? '
      '${status != null ? "AND p.status = ?" : ""} ORDER BY p.id DESC',
      [userId, if (status != null) status.name],
    );
    return rows.map(Perizinan.fromMap).toList();
  }

  /// Semua pengajuan (untuk pengurus), dengan filter opsional.
  Future<List<Perizinan>> getAll({
    StatusIzin? status,
    JenisIzin? jenis,
    String? cari,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (status != null) {
      where.add('p.status = ?');
      args.add(status.name);
    }
    if (jenis != null) {
      where.add('p.jenis = ?');
      args.add(jenis.name);
    }
    if (cari != null && cari.trim().isNotEmpty) {
      where.add('(u.nama LIKE ? OR u.no_identitas LIKE ?)');
      args
        ..add('%${cari.trim()}%')
        ..add('%${cari.trim()}%');
    }
    final rows = await db.rawQuery(
      '$_selectJoin ${where.isEmpty ? "" : "WHERE ${where.join(" AND ")}"} '
      'ORDER BY p.id DESC',
      args,
    );
    return rows.map(Perizinan.fromMap).toList();
  }

  /// Antrean izin menunggu yang boleh diproses oleh [pemroses].
  Future<List<Perizinan>> getAntrianUntuk(AppUser pemroses) async {
    final db = await _dbHelper.database;
    final level = pemroses.levelPengurus;
    final rows = await db.rawQuery(
      '''$_selectJoin
         WHERE p.status = 'menunggu'
           AND p.user_id != ?
           AND (u.level_pengurus < ? OR (? = 2 AND u.level_pengurus = 2))
         ORDER BY p.id ASC''',
      [pemroses.id, level, level],
    );
    return rows.map(Perizinan.fromMap).toList();
  }

  // ---------- UPDATE ----------
  /// Hanya pemilik, dan hanya selama status masih menunggu.
  Future<void> update(Perizinan izin) async {
    if (izin.id == null) throw PerizinanException('ID izin tidak valid.');
    final lama = await getById(izin.id!);
    _pastikanMilikDanMenunggu(lama, izin.userId);
    _validate(izin);
    final db = await _dbHelper.database;
    await _pastikanTidakBentrok(db, izin);
    await db.update(
      'perizinan',
      izin.toMap(),
      where: 'id = ?',
      whereArgs: [izin.id],
    );
  }

  Future<void> batalkan({required int izinId, required int userId}) async {
    final izin = await getById(izinId);
    _pastikanMilikDanMenunggu(izin, userId);
    final db = await _dbHelper.database;
    await db.update(
      'perizinan',
      {'status': StatusIzin.dibatalkan.name},
      where: 'id = ?',
      whereArgs: [izinId],
    );
  }

  /// Setujui atau tolak. Penolakan wajib menyertakan catatan.
  Future<void> proses({
    required int izinId,
    required AppUser pemroses,
    required bool setujui,
    String? catatan,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery('$_selectJoin WHERE p.id = ?', [izinId]);
      if (rows.isEmpty) throw PerizinanException('Pengajuan tidak ditemukan.');
      final izin = Perizinan.fromMap(rows.first);

      if (izin.status != StatusIzin.menunggu) {
        throw PerizinanException('Pengajuan ini sudah diproses.');
      }
      if (!PerizinanRules.bisaDiproses(pemroses: pemroses, izin: izin)) {
        throw PerizinanException('Anda tidak berwenang memproses izin ini.');
      }
      if (!setujui && (catatan == null || catatan.trim().isEmpty)) {
        throw PerizinanException('Alasan penolakan wajib diisi.');
      }

      final now = DateTime.now();
      final statusBaru = setujui ? StatusIzin.disetujui : StatusIzin.ditolak;

      await txn.update(
        'perizinan',
        {
          'status': statusBaru.name,
          'diproses_oleh': pemroses.id,
          'catatan_pengurus': catatan?.trim(),
          'tanggal_diproses': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [izinId],
      );

      await txn.insert('notifikasi', {
        'user_id': izin.userId,
        'perizinan_id': izinId,
        'judul': 'Izin ${statusBaru.label.toLowerCase()}',
        'isi':
            '${izin.jenis.label} Anda ${statusBaru.label.toLowerCase()}'
            '${setujui || catatan == null ? "." : ": ${catatan.trim()}"}',
        'dibaca': 0,
        'created_at': now.toIso8601String(),
      });
    });
  }

  // ---------- DELETE ----------
  Future<void> hapus({required int izinId, required int userId}) async {
    final izin = await getById(izinId);
    if (izin == null) throw PerizinanException('Pengajuan tidak ditemukan.');
    if (izin.userId != userId) {
      throw PerizinanException('Anda tidak berhak menghapus pengajuan ini.');
    }
    if (izin.status == StatusIzin.disetujui ||
        izin.status == StatusIzin.ditolak) {
      throw PerizinanException(
        'Pengajuan yang sudah diproses tidak dapat dihapus.',
      );
    }
    final db = await _dbHelper.database;
    await db.delete('perizinan', where: 'id = ?', whereArgs: [izinId]);
  }

  // ---------- Validasi & aturan ----------
  void _pastikanMilikDanMenunggu(Perizinan? izin, int userId) {
    if (izin == null) throw PerizinanException('Pengajuan tidak ditemukan.');
    if (izin.userId != userId) {
      throw PerizinanException('Ini bukan pengajuan Anda.');
    }
    if (izin.status != StatusIzin.menunggu) {
      throw PerizinanException(
        'Hanya pengajuan berstatus menunggu yang dapat diubah.',
      );
    }
  }

  void _validate(Perizinan i) {
    bool kosong(String? s) => s == null || s.trim().isEmpty;

    if (i.alasan.trim().length < 10) {
      throw PerizinanException('Alasan minimal 10 karakter.');
    }
    if (i.tanggalSelesai.isBefore(i.tanggalMulai)) {
      throw PerizinanException(
        'Tanggal selesai tidak boleh sebelum tanggal mulai.',
      );
    }
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    if (i.jenis != JenisIzin.sakit && i.tanggalMulai.isBefore(hariIni)) {
      throw PerizinanException('Tanggal mulai tidak boleh di masa lalu.');
    }
    switch (i.jenis) {
      case JenisIzin.keluar:
        if (kosong(i.jamKeluar) || kosong(i.jamKembali) || kosong(i.tujuan)) {
          throw PerizinanException(
            'Jam keluar, jam kembali, dan tujuan wajib diisi.',
          );
        }
        // Format "HH:mm" berpadding nol, jadi perbandingan teks sudah benar.
        if (i.jamKembali!.compareTo(i.jamKeluar!) <= 0) {
          throw PerizinanException('Jam kembali harus setelah jam keluar.');
        }
      case JenisIzin.pulang:
        if (kosong(i.tujuan) || kosong(i.penjemput)) {
          throw PerizinanException('Tujuan dan penjemput wajib diisi.');
        }
      case JenisIzin.sakit:
        if (kosong(i.keluhan)) {
          throw PerizinanException('Keluhan wajib diisi.');
        }
    }
  }

  Future<void> _pastikanTidakBentrok(Database db, Perizinan i) async {
    final rows = await db.query(
      'perizinan',
      columns: ['id'],
      where:
          "user_id = ? AND status IN ('menunggu', 'disetujui') "
          'AND tanggal_mulai <= ? AND tanggal_selesai >= ? '
          '${i.id != null ? "AND id != ?" : ""}',
      whereArgs: [
        i.userId,
        toDbDate(i.tanggalSelesai),
        toDbDate(i.tanggalMulai),
        if (i.id != null) i.id,
      ],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      throw PerizinanException(
        'Tanggal bentrok dengan pengajuan lain yang masih aktif.',
      );
    }
  }
}
