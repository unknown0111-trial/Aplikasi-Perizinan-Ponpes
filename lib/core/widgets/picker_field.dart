import 'package:material_ui/material_ui.dart';

class PickerField extends FormField<Object?> {
  PickerField({
    super.key,
    required String label,
    required IconData icon,
    required String? teks, // null = belum dipilih
    required VoidCallback onTap,
    String? Function()? cek,
  }) : super(
         validator: (_) => cek?.call(),
         builder: (state) => InkWell(
           borderRadius: BorderRadius.circular(12),
           onTap: onTap,
           child: InputDecorator(
             isEmpty: teks == null,
             decoration: InputDecoration(
               labelText: label,
               prefixIcon: Icon(icon),
               suffixIcon: const Icon(Icons.arrow_drop_down),
               errorText: state.errorText,
             ),
             child: Text(teks ?? '', overflow: TextOverflow.ellipsis),
           ),
         ),
       );
}
