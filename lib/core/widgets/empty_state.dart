import 'package:material_ui/material_ui.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.judul,
    this.pesan,
    this.aksiLabel,
    this.onAksi,
  });

  final IconData icon;
  final String judul;
  final String? pesan;
  final String? aksiLabel;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (pesan != null) ...[
              const SizedBox(height: 6),
              Text(
                pesan!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (aksiLabel != null && onAksi != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(onPressed: onAksi, child: Text(aksiLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
