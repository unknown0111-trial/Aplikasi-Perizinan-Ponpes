import 'package:material_ui/material_ui.dart';

import '../../core/utils/izin_ui.dart';
import '../../data/models/enums.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';

class AjukanScreen extends StatelessWidget {
  const AjukanScreen({super.key, this.rute = IzinRoutes.santri});
  final IzinRoutes rute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Izin')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Pilih jenis izin',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final jenis in JenisIzin.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push(rute.form(jenis.name)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            jenis.icon,
                            color: scheme.onPrimaryContainer,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jenis.label,
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                jenis.deskripsi,
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
