import 'package:intl/intl.dart';

import 'kurus.dart';

const String paraSimgesi = '₺';

final NumberFormat _binlikBicimi = NumberFormat('#,##0', 'tr_TR');

/// Parasal değeri Türkçe biçimde metne çevirir: `9400000` → `94.000,00 ₺`
///
/// Binlik ayracı nokta, ondalık ayracı virgüldür. Kuruş her zaman iki hanedir.
/// Negatif değerler başta eksi işaretiyle gösterilir: `-12.031,25 ₺`
///
/// Hesaplama tam sayı üzerinden yapılır; biçimleme aşamasında bile `double`
/// kullanılmaz.
String kurusBicimle(Kurus tutar, {bool simgeli = true}) {
  final govde = '${_binlikBicimi.format(tutar.liraKismi)}'
      ',${tutar.kurusKismi.toString().padLeft(2, '0')}';
  final isaret = tutar.negatifMi ? '-' : '';
  return simgeli ? '$isaret$govde $paraSimgesi' : '$isaret$govde';
}

/// Miktarı Türkçe binlik ayracıyla biçimler: `7000` → `7.000`
String miktarBicimle(int miktar) => _binlikBicimi.format(miktar);

extension KurusBicimi on Kurus {
  /// `94.000,00 ₺`
  String get bicimli => kurusBicimle(this);

  /// `94.000,00`
  String get bicimliSimgesiz => kurusBicimle(this, simgeli: false);
}
