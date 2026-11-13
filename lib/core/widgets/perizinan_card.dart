import 'package:material_ui/material_ui.dart';

import '../../data/models/perizinan_model.dart';
import '../utils/formatters.dart';
import '../utils/izin_ui.dart';
import 'status_chip.dart';

class PerizinanCard extends StatelessWidget {
  const PerizinanCard({
    super.key,
    required this.izin,
    this.onTap,
    this.tampilkanPemohon = false,
    this.perluTindakan = false,
  });

  final Perizinan izin;
  final VoidCallback? onTap;

  /// Untuk pengurus: judul kartu berupa nama pemohon.
  final bool tampilkanPemohon;

  /// Beri bingkai penekanan pada izin yang menunggu keputusan pengguna ini.
  final bool perluTindakan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final rentang = Fmt.rentang(izin.tanggalMulai, izin.tanggalSelesai);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: perluTindakan
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.primary, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(izin.jenis.icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tampilkanPemohon ? izin.namaPemohon : izin.jenis.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tampilkanPemohon
                          ? '${izin.jenis.label} • $rentang'
                          : rentang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      izin.alasan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(izin.status),
            ],
          ),
        ),
      ),
    );
  }
}
