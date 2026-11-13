import '../datasources/database_helper.dart';
import '../models/notifikasi_model.dart';

class NotifikasiRepository {
  NotifikasiRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<AppNotifikasi>> getByUser(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'notifikasi',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(AppNotifikasi.fromMap).toList();
  }

  Future<int> jumlahBelumDibaca(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notifikasi WHERE user_id = ? AND dibaca = 0',
      [userId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> tandaiSemuaDibaca(int userId) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifikasi',
      {'dibaca': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> tandaiDibaca(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifikasi',
      {'dibaca': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
