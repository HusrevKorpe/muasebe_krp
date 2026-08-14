import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';

/// Kişi listesinin arama kutusu.
///
/// Yalnızca "Tümü" sekmesinde görünür: açık hesap sorgusu bakiyeye aralık
/// süzgeci uyguluyor ve Firestore aynı sorguda ikinci bir aralık süzgecini
/// sıralayamıyor (bkz. `CariRepository.listeyiIzle`). Aranan kişinin bakiyesi
/// zaten "Tümü" listesindeki satırında yazıyor.
class CariAramaAlani extends StatelessWidget {
  const CariAramaAlani({
    required this.kontrolcu,
    required this.onDegisti,
    super.key,
  });

  final TextEditingController kontrolcu;
  final ValueChanged<String> onDegisti;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: kontrolcu,
        onChanged: onDegisti,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: Metinler.cariAra,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: kontrolcu,
            builder: (context, deger, _) => deger.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: Metinler.temizle,
                    onPressed: () {
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
