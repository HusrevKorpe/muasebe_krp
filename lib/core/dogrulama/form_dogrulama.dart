/// Form alanı doğrulamaları. Hata dönerse metin, geçerliyse `null` döner —
/// Flutter'ın `TextFormField.validator` sözleşmesine uyar.
abstract final class FormDogrulama {
  /// Kabaca doğru bir e-posta biçimi arar. Kesin doğrulama sunucuda yapılır;
  /// buradaki amaç kullanıcıyı yazım hatasında erken uyarmak.
  static final RegExp _ePostaKalibi = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? ePosta(String? deger) {
    final metin = deger?.trim() ?? '';
    if (metin.isEmpty) return 'E-posta adresi gerekli.';
    if (!_ePostaKalibi.hasMatch(metin)) return 'Geçerli bir e-posta girin.';
    return null;
  }

  /// Uzunluk sınırı yok: şifreyi Firebase Console koyuyor, uygulama yalnızca
  /// soruyor. Boş alanı erken yakalamak yeter — gerisini sunucu söyler.
  static String? sifre(String? deger) {
    if ((deger ?? '').isEmpty) return 'Şifre gerekli.';
    return null;
  }

  /// Boş bırakılamayan metin alanları için.
  static String? zorunlu(String? deger, String alanAdi) {
    if ((deger?.trim() ?? '').isEmpty) return '$alanAdi gerekli.';
    return null;
  }
}
