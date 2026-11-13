import 'package:material_ui/material_ui.dart';

import '../../data/models/enums.dart';
import '../utils/izin_ui.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final StatusIzin status;

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
