import 'package:flutter/foundation.dart';

import '../../data/models/notifikasi_model.dart';
import '../../data/repositories/notifikasi_repository.dart';

class NotifikasiProvider extends ChangeNotifier {
  NotifikasiProvider(this._repo, this.userId);

  final NotifikasiRepository _repo;
  final int userId;

  List<AppNotifikasi> _items = [];
  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;

  List<AppNotifikasi> get items => _items;
  bool get hasLoaded => _loaded;
  int get belumDibaca => _items.where((n) => !n.dibaca).length;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      _items = await _repo.getByUser(userId);
    } catch (_) {
      // Notifikasi tidak kritis: biarkan daftar lama.
    } finally {
      _loading = false;
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> tandaiDibaca(AppNotifikasi n) async {
    if (n.dibaca) return;
    await _repo.tandaiDibaca(n.id);
    await load();
  }

  Future<void> tandaiSemuaDibaca() async {
    await _repo.tandaiSemuaDibaca(userId);
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
