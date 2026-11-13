enum UserRole { santri, pengurus }

enum JenisIzin {
  keluar('Izin Keluar'),
  pulang('Izin Pulang'),
  sakit('Izin Sakit');

  const JenisIzin(this.label);
  final String label;
}

enum StatusIzin {
  menunggu('Menunggu'),
  disetujui('Disetujui'),
  ditolak('Ditolak'),
  dibatalkan('Dibatalkan');

  const StatusIzin(this.label);
  final String label;
}
