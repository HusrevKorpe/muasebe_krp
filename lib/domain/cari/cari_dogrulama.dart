/// Cari formu alan doğrulamaları.
///
/// Hata varsa Türkçe mesaj, geçerliyse `null` döner — Flutter'ın
/// `TextFormField.validator` sözleşmesine uyar. Saf Dart olduğu için cihazsız
/// test edilir (bkz. KURALLAR.md §5.1).
abstract final class CariDogrulama {
  /// Ad tek zorunlu alandır: bir cari en azından bir isimle açılabilmeli,
  /// adres ve iletişim bilgisi sonradan tamamlanabilir.
  static const int enAzAdUzunlugu = 2;

  static String? ad(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Cari adı gerekli.';
    if (metin.length < enAzAdUzunlugu) {
      return 'Cari adı en az $enAzAdUzunlugu karakter olmalı.';
    }
    return null;
  }

  /// Telefon isteğe bağlıdır. Biçim zorlanmaz — kullanıcı sabit hat, cep ya da
  /// yurt dışı numarası girebilir; yalnızca anlamsız kısalık engellenir.
  static const int enAzTelefonHanesi = 7;

  static String? telefon(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return null;

    final rakamlar = metin.replaceAll(RegExp(r'\D'), '');
    if (rakamlar.length < enAzTelefonHanesi) {
      return 'Telefon numarası eksik görünüyor.';
    }
    return null;
  }
}
