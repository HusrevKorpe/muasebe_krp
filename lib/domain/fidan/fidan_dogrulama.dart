import '../../core/para/para_girisi.dart';

/// Fidan formu alan doğrulamaları.
///
/// Hata varsa Türkçe mesaj, geçerliyse `null` döner — Flutter'ın
/// `TextFormField.validator` sözleşmesine uyar. Saf Dart olduğu için cihazsız
/// test edilir (bkz. KURALLAR.md §5.1).
abstract final class FidanDogrulama {
  /// Tür ve çeşit zorunludur: fidanın kimliği bu ikisiyle başlar. Anaç, yaş ve
  /// kök tipi sonradan tamamlanabilir.
  static const int enAzUzunluk = 2;

  /// Fidancılıkta satılan fidan bu yaşın üstüne çıkmaz; daha büyük bir sayı
  /// neredeyse kesinlikle yanlış alana yazılmış bir fiyat ya da miktardır.
  static const int enBuyukYas = 20;

  static String? tur(String? deger) => _zorunluAd(deger, 'Tür');

  static String? cesit(String? deger) => _zorunluAd(deger, 'Çeşit');

  /// Yaş isteğe bağlıdır; girilirse makul aralıkta bir tam sayı olmalıdır.
  static String? yas(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return null;

    final sayi = int.tryParse(metin);
    if (sayi == null || sayi < 0 || sayi > enBuyukYas) {
      return 'Yaş 0 ile $enBuyukYas arasında bir tam sayı olmalı.';
    }
    return null;
  }

  /// Varsayılan fiyat isteğe bağlıdır: fiyatı değişken olan fidan katalogda
  /// fiyatsız durabilir, kullanıcı tutarı faturada girer.
  static String? varsayilanFiyat(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return null;

    final tutar = kurusAyristir(metin);
    if (tutar == null) return 'Geçerli bir tutar yazın: 31.000,00';
    if (tutar.negatifMi) return 'Fiyat negatif olamaz.';
    return null;
  }

  static String? _zorunluAd(String? deger, String alanAdi) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return '$alanAdi gerekli.';
    if (metin.length < enAzUzunluk) {
      return '$alanAdi en az $enAzUzunluk karakter olmalı.';
    }
    return null;
  }
}
