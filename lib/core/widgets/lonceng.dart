import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/notifikasi/notifikasi_provider.dart';

class Lonceng extends StatelessWidget {
  const Lonceng({super.key, required this.rute});
  final String rute;

  @override
  Widget build(BuildContext context) {
    final n = context.select<NotifikasiProvider, int>((p) => p.belumDibaca);
    return IconButton.filledTonal(
      tooltip: 'Notifikasi',
      onPressed: () => context.push(rute),
      icon: Badge(
        label: Text(n > 99 ? '99+' : '$n'),
        isLabelVisible: n > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
