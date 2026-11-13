import 'package:sqflite/sqflite.dart';

import '../../core/utils/password_hasher.dart';
import '../models/perizinan_model.dart';

class SeedData {
  /// Password pengurus untuk pengembangan. Ganti sebelum dipakai sungguhan.
  static const devPassword = 'pengurus123';

  static Future<void> insert(Database db) async {
    final batch = db.batch();

    // Santri: id 1-6
    const santri = [
      (1, 'Ahmad Fauzi', '2024001', '1 Aliyah'),
      (2, 'Muhammad Rizki', '2024002', '1 Aliyah'),
      (3, 'Abdullah Hakim', '2024003', '2 Aliyah'),
      (4, 'Yusuf Maulana', '2024004', '2 Aliyah'),
      (5, 'Ilham Ramadhan', '2024005', '3 Aliyah'),
      (6, 'Zaki Mubarak', '2024006', '3 Aliyah'),
    ];
    for (final s in santri) {
      batch.insert('users', {
        'id': s.$1,
        'nama': s.$2,
        'no_identitas': s.$3,
        'role': 'santri',
        'level_pengurus': 0,
        'kelas': s.$4,
      });
    }

    // Pengurus: id 7-8 (level 1), id 9-10 (level 2)
    const pengurus = [
      (7, 'Ustadz Hasan', 'P-001', 1),
      (8, 'Ustadz Umar', 'P-002', 1),
      (9, 'Ustadz Ali', 'P-003', 2),
      (10, 'Ustadz Bakar', 'P-004', 2),
    ];
    for (final p in pengurus) {
      final salt = PasswordHasher.generateSalt();
      batch.insert('users', {
        'id': p.$1,
        'nama': p.$2,
        'no_identitas': p.$3, // dipakai sebagai username
        'password_hash': PasswordHasher.hash(devPassword, salt),
        'salt': salt,
        'role': 'pengurus',
        'level_pengurus': p.$4,
      });
    }

    // Contoh pengajuan untuk menguji alur
    final now = DateTime.now();
    DateTime d(int plus) => DateTime(now.year, now.month, now.day + plus);

    batch.insert('perizinan', {
      'user_id': 1,
      'jenis': 'keluar',
      'tanggal_pengajuan': toDbDate(now),
      'tanggal_mulai': toDbDate(d(1)),
      'tanggal_selesai': toDbDate(d(1)),
      'jam_keluar': '14:00',
      'jam_kembali': '17:00',
      'tujuan': 'Toko buku',
      'alasan': 'Membeli buku pelajaran',
      'status': 'menunggu',
    });
    batch.insert('perizinan', {
      'user_id': 2,
      'jenis': 'sakit',
      'tanggal_pengajuan': toDbDate(now),
      'tanggal_mulai': toDbDate(now),
      'tanggal_selesai': toDbDate(d(2)),
      'keluhan': 'Demam dan pusing',
      'alasan': 'Perlu istirahat di asrama',
      'status': 'disetujui',
      'diproses_oleh': 7,
      'tanggal_diproses': now.toIso8601String(),
    });
    batch.insert('perizinan', {
      'user_id': 8, // pengurus level 1 -> hanya level 2 yang bisa memproses
      'jenis': 'pulang',
      'tanggal_pengajuan': toDbDate(now),
      'tanggal_mulai': toDbDate(d(5)),
      'tanggal_selesai': toDbDate(d(8)),
      'tujuan': 'Rumah keluarga',
      'penjemput': 'Orang tua',
      'alasan': 'Menghadiri acara keluarga',
      'status': 'menunggu',
    });

    await batch.commit(noResult: true);
  }
}
