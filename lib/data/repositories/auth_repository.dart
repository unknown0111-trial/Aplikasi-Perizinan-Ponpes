import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/password_hasher.dart';
import '../datasources/database_helper.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  static const _sessionKey = 'session_user_id';

  Future<AppUser> loginSantri({
    required String nama,
    required String noIdentitas,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: "role = 'santri' AND no_identitas = ? AND LOWER(nama) = LOWER(?)",
      whereArgs: [noIdentitas.trim(), nama.trim()],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw AuthException('Nama atau nomor identitas tidak sesuai.');
    }
    final user = AppUser.fromMap(rows.first);
    await _saveSession(user.id!);
    return user;
  }

  Future<AppUser> loginPengurus({
    required String username,
    required String password,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: "role = 'pengurus' AND no_identitas = ?",
      whereArgs: [username.trim()],
      limit: 1,
    );
    if (rows.isEmpty) throw AuthException('Username atau password salah.');

    final user = AppUser.fromMap(rows.first);
    final ok =
        user.salt != null &&
        user.passwordHash != null &&
        PasswordHasher.verify(password, user.salt!, user.passwordHash!);
    if (!ok) throw AuthException('Username atau password salah.');

    await _saveSession(user.id!);
    return user;
  }

  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id == null) return null;
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> _saveSession(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, id);
  }

  Future<void> gantiPassword({
    required int userId,
    required String lama,
    required String baru,
  }) async {
    if (baru.length < 8) {
      throw AuthException('Password baru minimal 8 karakter.');
    }
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: "id = ? AND role = 'pengurus'",
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) throw AuthException('Akun tidak ditemukan.');

    final u = AppUser.fromMap(rows.first);
    final ok =
        u.salt != null &&
        u.passwordHash != null &&
        PasswordHasher.verify(lama, u.salt!, u.passwordHash!);
    if (!ok) throw AuthException('Password lama salah.');

    final salt = PasswordHasher.generateSalt();
    await db.update(
      'users',
      {'password_hash': PasswordHasher.hash(baru, salt), 'salt': salt},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<AppUser> ubahNoHpWali({required int userId, String? noHp}) async {
    final db = await _dbHelper.database;
    final bersih = (noHp == null || noHp.trim().isEmpty) ? null : noHp.trim();
    await db.update(
      'users',
      {'no_hp_wali': bersih},
      where: 'id = ?',
      whereArgs: [userId],
    );
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) throw AuthException('Pengguna tidak ditemukan.');
    return AppUser.fromMap(rows.first);
  }
}
