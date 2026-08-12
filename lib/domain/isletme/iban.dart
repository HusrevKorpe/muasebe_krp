/// IBAN doğrulama ve biçimleme.
///
/// IBAN ekstrenin alt bilgisine basılıyor; yanlış bir hane müşterinin parayı
/// başka hesaba göndermesi demek. Bu yüzden yalnızca uzunluğa bakılmaz,
/// ISO 13616'nın mod-97 kontrolü de uygulanır.
abstract final class Iban {
  static const String ulkeKodu = 'TR';

  /// Türkiye IBAN'ı sabit 26 karakterdir: `TR` + 2 kontrol + 5 banka +
  /// 1 rezerv + 16 hesap.
  static const int turkiyeUzunlugu = 26;

  /// Yalnızca `TR` ile başlayan, 24 rakam içeren IBAN kabul edilir.
  static final RegExp _turkiyeKalibi = RegExp(r'^TR\d{24}$');

  /// Boşluk ve tireleri atıp büyük harfe çevirir.
  ///
  /// IBAN alfabesi ASCII olduğu için burada Dart'ın yerleşik [String.toUpperCase]
  /// dönüşümü doğrudur; Türkçe `i`/`ı` sorunu IBAN'da oluşamaz
  /// (bkz. KURALLAR.md §6.1).
  static String normalize(String metin) =>
      metin.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();

  static bool gecerliMi(String metin) {
    final iban = normalize(metin);
    if (iban.length != turkiyeUzunlugu) return false;
    if (!_turkiyeKalibi.hasMatch(iban)) return false;
    return _mod97(iban) == 1;
  }

  /// Okunabilir biçime çevirir: `TR330006100519786457841326` →
  /// `TR33 0006 1005 1978 6457 8413 26`
  static String bicimle(String metin) {
    final iban = normalize(metin);
    final tampon = StringBuffer();
    for (var sira = 0; sira < iban.length; sira++) {
      if (sira > 0 && sira % 4 == 0) tampon.write(' ');
      tampon.write(iban[sira]);
    }
    return tampon.toString();
  }

  /// ISO 13616 mod-97 kontrolü.
  ///
  /// İlk dört karakter sona alınır, harfler `A=10 … Z=35` olacak şekilde
  /// rakama çevrilir ve oluşan dev sayının 97'ye bölümünden kalan 1 olmalıdır.
  /// Sayı tek seferde tutulamayacak kadar uzun olduğu için kalan hane hane
  /// ilerletilir — `BigInt` gerekmez.
  static int _mod97(String iban) {
    final yenidenDizilmis = iban.substring(4) + iban.substring(0, 4);
    var kalan = 0;
    for (final kod in yenidenDizilmis.codeUnits) {
      // 'A'..'Z' → 10..35, '0'..'9' → 0..9
      final deger = kod >= 0x41 ? kod - 0x41 + 10 : kod - 0x30;
      if (deger >= 10) {
        kalan = (kalan * 100 + deger) % 97;
      } else {
        kalan = (kalan * 10 + deger) % 97;
      }
    }
    return kalan;
  }
}
