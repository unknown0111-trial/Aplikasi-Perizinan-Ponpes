import 'package:material_ui/material_ui.dart';

import '../../data/models/enums.dart';
import '../theme/app_theme.dart';

extension JenisIzinUi on JenisIzin {
  IconData get icon => switch (this) {
    JenisIzin.keluar => Icons.directions_walk_rounded,
    JenisIzin.pulang => Icons.home_outlined,
    JenisIzin.sakit => Icons.medical_services_outlined,
  };

  String get deskripsi => switch (this) {
    JenisIzin.keluar =>
      'Keluar area pesantren sementara dan kembali di hari yang sama.',
    JenisIzin.pulang => 'Pulang ke rumah selama beberapa hari.',
    JenisIzin.sakit => 'Istirahat atau berobat karena sakit.',
  };
}

extension StatusIzinUi on StatusIzin {
  Color get color => switch (this) {
    StatusIzin.menunggu => AppTheme.menunggu,
    StatusIzin.disetujui => AppTheme.disetujui,
    StatusIzin.ditolak => AppTheme.ditolak,
    StatusIzin.dibatalkan => AppTheme.dibatalkan,
  };

  IconData get icon => switch (this) {
    StatusIzin.menunggu => Icons.hourglass_top_rounded,
    StatusIzin.disetujui => Icons.check_circle_outline,
    StatusIzin.ditolak => Icons.cancel_outlined,
    StatusIzin.dibatalkan => Icons.block,
  };
}
