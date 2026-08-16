import 'package:flutter/material.dart';

import '../../core/metin/metinler.dart';
import 'olculer.dart';
import 'simge_dugmesi.dart';

/// Liste ekranlarının arama kutusu.
///
/// Kişi, ürün ve seçenek listelerinde birbirinin kopyası üç kutu vardı; üçü de
/// aynı işi yapıyordu ama biri temizleme düğmesini gösterirken öbürü ipucu
/// metnini farklı hizalıyordu. Tek bileşen: aynı yükseklik, aynı temizleme
/// davranışı, aynı kenar boşluğu.
///
/// Hap biçimli: metin kutularından ayrılsın diye. Ekrandaki öteki kutular
/// doldurulacak alanlar, bu ise bir araç.
class AramaAlani extends StatelessWidget {
  const AramaAlani({
    required this.kontrolcu,
    required this.ipucu,
    required this.onDegisti,
    super.key,
  });

  final TextEditingController kontrolcu;
  final String ipucu;
  final ValueChanged<String> onDegisti;

  @override
  Widget build(BuildContext context) {
    final sema = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Olculer.sayfaKenari,
        Olculer.bosluk12,
        Olculer.sayfaKenari,
        Olculer.bosluk8,
      ),
      child: TextField(
        controller: kontrolcu,
        onChanged: onDegisti,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: ipucu,
          prefixIcon: const Icon(Icons.search, size: 21),
          isDense: true,
          filled: true,
          fillColor: sema.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(
            vertical: Olculer.bosluk12,
            horizontal: Olculer.bosluk12,
          ),
          border: const OutlineInputBorder(
            borderRadius: Olculer.koseTam,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: Olculer.koseTam,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: Olculer.koseTam,
            borderSide: BorderSide(color: sema.primary, width: 1.8),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: kontrolcu,
            builder: (context, deger, _) => deger.text.isEmpty
                ? const SizedBox.shrink()
                : SimgeDugmesi(
                    simge: Icons.close,
                    ipucu: Metinler.temizle,
                    onBasildi: () {
                      kontrolcu.clear();
                      onDegisti('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
