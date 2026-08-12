/// Form alanı doğrulamaları. Hata dönerse metin, geçerliyse `null` döner —
/// Flutter'ın `TextFormField.validator` sözleşmesine uyar.
abstract final class FormDogrulama {
  /// Kabaca doğru bir e-posta biçimi arar. Kesin doğrulama sunucuda yapılır;
  /// buradaki amaç kullanıcıyı yazım hatasında erken uyarmak.
  static final RegExp _ePostaKalibi = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Firebase Auth'un en düşük şifre uzunluğu.
  static const int enAzSifreUzunlugu = 6;

  static String? ePosta(String? deger) {
    final metin = deger?.trim() ?? '';
    if (metin.isEmpty) return 'E-posta adresi gerekli.';
    if (!_ePostaKalibi.hasMatch(metin)) return 'Geçerli bir e-posta girin.';
    return null;
  }

  static String? sifre(String? deger) {
    final metin = deger ?? '';
    if (metin.isEmpty) return 'Şifre gerekli.';
    if (metin.length < enAzSifreUzunlugu) {
      return 'Şifre en az $enAzSifreUzunlugu karakter olmalı.';
    }
    return null;
  }

  static String? sifreTekrari(String? deger, String sifre) {
    if ((deger ?? '').isEmpty) return 'Şifreyi tekrar girin.';
    if (deger != sifre) return 'Şifreler eşleşmiyor.';
    return null;
  }

  /// Boş bırakılamayan metin alanları için.
  static String? zorunlu(String? deger, String alanAdi) {
    if ((deger?.trim() ?? '').isEmpty) return '$alanAdi gerekli.';
    return null;
  }
}
