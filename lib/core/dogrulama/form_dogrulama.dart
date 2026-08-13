/// Form alanı doğrulamaları. Hata dönerse metin, geçerliyse `null` döner —
/// Flutter'ın `TextFormField.validator` sözleşmesine uyar.
abstract final class FormDogrulama {
  /// Boş bırakılamayan metin alanları için.
  static String? zorunlu(String? deger, String alanAdi) {
    if ((deger?.trim() ?? '').isEmpty) return '$alanAdi gerekli.';
    return null;
  }
}
