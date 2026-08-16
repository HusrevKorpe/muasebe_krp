import 'package:flutter/material.dart';

import '../../../../app/tasarim/arama_alani.dart';
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
    return AramaAlani(
      kontrolcu: kontrolcu,
      ipucu: Metinler.cariAra,
      onDegisti: onDegisti,
    );
  }
}
