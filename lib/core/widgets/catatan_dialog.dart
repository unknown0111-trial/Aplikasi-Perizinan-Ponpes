import 'package:material_ui/material_ui.dart';

class CatatanDialog extends StatefulWidget {
  const CatatanDialog({
    super.key,
    required this.judul,
    this.deskripsi,
    required this.label,
    required this.aksi,
    this.wajib = false,
    this.bahaya = false,
  });

  final String judul;
  final String? deskripsi;
  final String label;
  final String aksi;
  final bool wajib;
  final bool bahaya;

  @override
  State<CatatanDialog> createState() => _CatatanDialogState();
}

class _CatatanDialogState extends State<CatatanDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _kirim() {
    final t = _ctrl.text.trim();
    if (widget.wajib && t.length < 5) {
      setState(() => _error = '${widget.label} minimal 5 karakter');
      return;
    }
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      title: Text(widget.judul),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.deskripsi != null) ...[
            Text(widget.deskripsi!),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _ctrl,
            autofocus: widget.wajib,
            minLines: 2,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: _error,
              alignLabelWithHint: true,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: widget.bahaya ? scheme.error : null,
            foregroundColor: widget.bahaya ? scheme.onError : null,
          ),
          onPressed: _kirim,
          child: Text(widget.aksi),
        ),
      ],
    );
  }
}
