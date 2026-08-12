/// Kullanıcının yazdığı tutar ve miktar metinlerini tam sayıya çevirir.
///
/// Çevrim `double`'a hiç uğramaz: `double.parse('0.1')` ile başlayan her yol
/// kuruşta sapma bırakır (bkz. KURALLAR.md §3.1). Metin, tam sayı lira ve tam
/// sayı kuruş parçalarına ayrılıp doğrudan tam sayı aritmetiğiyle birleştirilir.
library;

import 'kurus.dart';
import 'para_bicimi.dart';

/// Kuruş her zaman iki hanedir; daha uzun ondalık para değeri değildir.
const int _enCokOndalikHane = 2;

/// Tutar metnini [Kurus]'a çevirir.
///
/// Kabul edilen yazımlar: `94000`, `94.000`, `94000,50`, `94.000,50`, `18,79`,
/// `-12.031,25`, `1.234,5`, ` 94.000,00 ₺ `
///
/// Geçersiz girdide `null` döner — form alanı hata gösterir, sessizce sıfır
/// kaydedilmez.
Kurus? kurusAyristir(String? metin) {
  final temiz = _temizle(metin);
  if (temiz.isEmpty) return null;

  final negatifMi = temiz.startsWith('-');
  final govde = negatifMi ? temiz.substring(1) : temiz;
  if (govde.isEmpty) return null;

  final (tamKisim, ondalikKisim) = _parcala(govde);
  if (tamKisim == null) return null;
  // Yalnızca ayraçtan ibaret girdi ("," ya da ".") tutar değildir.
  if (tamKisim.isEmpty && (ondalikKisim == null || ondalikKisim.isEmpty)) {
    return null;
  }
  if (ondalikKisim != null && ondalikKisim.length > _enCokOndalikHane) {
    return null;
  }

  final lira = int.tryParse(tamKisim.isEmpty ? '0' : tamKisim);
  if (lira == null) return null;

  // '5' → 50 kuruş, '05' → 5 kuruş. Eksik hane sonda sıfırla tamamlanır.
  final kurus = ondalikKisim == null || ondalikKisim.isEmpty
      ? 0
      : int.tryParse(ondalikKisim.padRight(_enCokOndalikHane, '0'));
  if (kurus == null) return null;

  final toplam = lira * 100 + kurus;
  return Kurus(negatifMi ? -toplam : toplam);
}

/// Miktar alanı için: `7.000` → `7000`. Ondalık kabul edilmez.
int? miktarAyristir(String? metin) {
  final temiz = _temizle(metin).replaceAll('.', '');
  if (temiz.isEmpty || temiz.contains(',')) return null;
  return int.tryParse(temiz);
}

/// Tutarı düzenlenebilir metne çevirir: `9400000` → `94.000,00`
///
/// Para simgesi konmaz; alanın kendisi zaten ₺ ile etiketlenir.
String kurusMetni(Kurus tutar) => tutar.bicimliSimgesiz;

String _temizle(String? metin) =>
    (metin ?? '').replaceAll(paraSimgesi, '').replaceAll(RegExp(r'\s'), '');

/// Metni tam ve ondalık parçalarına ayırır. Tam kısım `null` ise girdi geçersiz.
///
/// Ayraç belirsizliği burada çözülür: `1.234` binlik ayraçlı bin iki yüz otuz
/// dört, `1.23` ise bir lira yirmi üç kuruştur. Ölçüt son ayraçtan sonraki hane
/// sayısıdır — üç haneyse binlik ayracıdır.
(String?, String?) _parcala(String govde) {
  if (!_yalnizcaRakamVeAyrac(govde)) return (null, null);

  if (govde.contains(',')) {
    final parcalar = govde.split(',');
    if (parcalar.length != 2) return (null, null);
    final tam = parcalar.first.replaceAll('.', '');
    return (_rakamMi(tam, bosOlabilir: true) ? tam : null, parcalar.last);
  }

  if (govde.contains('.')) {
    final parcalar = govde.split('.');
    final son = parcalar.last;
    final binlikMi = parcalar.length > 1 && son.length == 3;
    if (binlikMi) {
      final tam = govde.replaceAll('.', '');
      return (_rakamMi(tam) ? tam : null, null);
    }
    if (parcalar.length != 2) return (null, null);
    final tam = parcalar.first;
    return (_rakamMi(tam, bosOlabilir: true) ? tam : null, son);
  }

  return (_rakamMi(govde) ? govde : null, null);
}

bool _yalnizcaRakamVeAyrac(String metin) =>
    RegExp(r'^[0-9.,]+$').hasMatch(metin);

bool _rakamMi(String metin, {bool bosOlabilir = false}) {
  if (metin.isEmpty) return bosOlabilir;
  return RegExp(r'^[0-9]+$').hasMatch(metin);
}
