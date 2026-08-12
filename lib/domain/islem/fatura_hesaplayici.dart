import '../../core/para/kurus.dart';
import '../../core/para/yuvarlama.dart';
import 'fatura_toplami.dart';
import 'islem_kalemi.dart';

/// Kalem listesinden fatura toplamını üretir.
///
/// Hesap baştan sona kuruş cinsinden tam sayıyla yürür; hiçbir adımda `double`
/// kullanılmaz (bkz. KURALLAR.md §3.1).
abstract final class FaturaHesaplayici {
  /// Fidan KDV oranı. Fatura bazında opsiyoneldir; kullanıcı KDV'yi açtığında
  /// forma bu oran gelir.
  static const int varsayilanKdvOrani = 1;

  /// KDV kapalı fatura.
  static const int kdvsiz = 0;

  /// Ara toplam → KDV → genel toplam.
  ///
  /// [kdvOrani] yüzde olarak verilir: `1` → %1. `0` verilirse KDV satırı oluşmaz.
  static FaturaToplami hesapla({
    required List<IslemKalemi> kalemler,
    int kdvOrani = kdvsiz,
  }) {
    if (kdvOrani < 0) {
      throw ArgumentError.value(kdvOrani, 'kdvOrani', 'KDV oranı negatif olamaz');
    }

    final araToplam = kurusTopla(kalemler.map((kalem) => kalem.tutar));
    // KDV, kalem kalem değil ara toplam üzerinden hesaplanır: her kalemde ayrı
    // yuvarlama yapmak toplamda kuruş sapması bırakırdı.
    final kdv = kdvOrani == kdvsiz ? Kurus.sifir : yuzdesi(araToplam, kdvOrani);

    return FaturaToplami(
      araToplam: araToplam,
      kdvOrani: kdvOrani,
      kdv: kdv,
      toplam: araToplam + kdv,
    );
  }
}
