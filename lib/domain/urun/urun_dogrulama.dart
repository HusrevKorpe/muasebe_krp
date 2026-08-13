import '../../core/para/para_girisi.dart';

/// Ürün formu alan doğrulamaları.
///
/// Hata varsa Türkçe mesaj, geçerliyse `null` döner — Flutter'ın
/// `TextFormField.validator` sözleşmesine uyar. Saf Dart olduğu için cihazsız
/// test edilir (bkz. KURALLAR.md §5.1).
abstract final class UrunDogrulama {
  /// Ad tek zorunlu alan: ürünün kimliği o.
  static const int enAzUzunluk = 2;

  static String? ad(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Ürün adı gerekli.';
    if (metin.length < enAzUzunluk) {
      return 'Ürün adı en az $enAzUzunluk karakter olmalı.';
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
