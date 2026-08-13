import '../../core/para/kurus.dart';
import 'islem_kalemi.dart';

/// Kalem listesinden fatura toplamını üretir.
///
/// Hesap baştan sona kuruş cinsinden tam sayıyla yürür; hiçbir adımda `double`
/// kullanılmaz (bkz. KURALLAR.md §3.1).
abstract final class FaturaHesaplayici {
  /// Faturanın genel toplamı: kalem tutarlarının toplamı.
  ///
  /// Toplam üzerine binen bir vergi yoktur; kalemlerin dışında bir tutar
  /// eklenmez. Vergi gibi ek bir satır gerekiyorsa kullanıcı onu serbest metin
  /// kalemi olarak girer.
  static Kurus hesapla({required List<IslemKalemi> kalemler}) =>
      kurusTopla(kalemler.map((kalem) => kalem.tutar));
}
