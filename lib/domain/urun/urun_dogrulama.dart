import '../../core/para/para_girisi.dart';

/// Ürün formu alan doğrulamaları.
///
/// Hata varsa Türkçe mesaj, geçerliyse `null` döner — Flutter'ın
/// `TextFormField.validator` sözleşmesine uyar. Saf Dart olduğu için cihazsız
/// test edilir (bkz. KURALLAR.md §5.1).
abstract final class UrunDogrulama {
  /// Tür tek zorunlu alan: ürünün kimliği ondan başlıyor.
  static const int enAzUzunluk = 2;

  /// Çeşit ve anaç doğrulanmaz, çünkü ikisi de isteğe bağlı: `nakliye`
  /// kaleminin çeşidi yok, `çam` fidanının anacı yok. Boş bırakılan alan ada
  /// hiç girmez (bkz. [urunAdi]).
  static String? tur(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Tür gerekli.';
    if (metin.length < enAzUzunluk) {
      return 'Tür en az $enAzUzunluk karakter olmalı.';
    }
    return null;
  }

  /// Fiyat isteğe bağlıdır: fiyatı değişken olan ürün katalogda fiyatsız
  /// durabilir, kullanıcı tutarı faturada girer.
  static String? fiyat(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return null;

    final tutar = kurusAyristir(metin);
    if (tutar == null) return 'Geçerli bir tutar yazın: 31.000,00';
    if (tutar.negatifMi) return 'Fiyat negatif olamaz.';
    return null;
  }
}
