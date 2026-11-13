import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'perizinan_pesantren.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        no_identitas TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        salt TEXT,
        role TEXT NOT NULL CHECK (role IN ('santri', 'pengurus')),
        level_pengurus INTEGER NOT NULL DEFAULT 0,
        kelas TEXT,
        no_hp_wali TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE perizinan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        jenis TEXT NOT NULL CHECK (jenis IN ('keluar', 'pulang', 'sakit')),
        tanggal_pengajuan TEXT NOT NULL,
        tanggal_mulai TEXT NOT NULL,
        tanggal_selesai TEXT NOT NULL,
        jam_keluar TEXT,
        jam_kembali TEXT,
        tujuan TEXT,
        penjemput TEXT,
        keluhan TEXT,
        alasan TEXT NOT NULL,
        keterangan TEXT,
        status TEXT NOT NULL DEFAULT 'menunggu'
          CHECK (status IN ('menunggu', 'disetujui', 'ditolak', 'dibatalkan')),
        diproses_oleh INTEGER,
        catatan_pengurus TEXT,
        tanggal_diproses TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (diproses_oleh) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notifikasi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        perizinan_id INTEGER,
        judul TEXT NOT NULL,
        isi TEXT NOT NULL,
        dibaca INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (perizinan_id) REFERENCES perizinan (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_perizinan_user ON perizinan (user_id)');
    await db.execute('CREATE INDEX idx_perizinan_status ON perizinan (status)');
    await db.execute('CREATE INDEX idx_notif_user ON notifikasi (user_id)');

    await SeedData.insert(db);
  }

  /// Hanya untuk pengembangan: hapus database agar seed dibuat ulang.
  Future<void> resetForDev() async {
    await _db?.close();
    _db = null;
    await deleteDatabase(join(await getDatabasesPath(), _dbName));
  }
}
