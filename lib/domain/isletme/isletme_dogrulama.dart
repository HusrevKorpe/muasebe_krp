import '../cari/cari_dogrulama.dart';
import 'iban.dart';

/// İşletme profili ve banka hesabı doğrulamaları.
///
/// Cari formundan farklı olarak burada alanların çoğu **zorunludur**: bu bilgiler
/// Faz 4'te ekstre başlığına basılıyor ve eksik bırakılırsa müşteriye yarım
/// başlıklı bir belge gider. Kurulum ekranı bu yüzden atlanabilir değildir
/// (bkz. `fazlar/faz-1-cari.md` → Riskler).
abstract final class IsletmeDogrulama {
  static String? ad(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'İşletme adı gerekli.';
    return null;
  }

  static String? adres(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Adres gerekli. Ekstre başlığında görünecek.';
    return null;
  }

  static String? telefon(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Telefon gerekli.';
    return CariDogrulama.telefon(deger);
  }

  static String? vergiDairesi(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Vergi dairesi gerekli.';
    return null;
  }

  /// Cari tarafından farklı olarak burada numara zorunludur; biçim kontrolü
  /// aynı kurallardan geçer.
  static String? vergiNo(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Vergi no gerekli.';
    return CariDogrulama.vergiNo(deger);
  }

  static String? bankaAdi(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Banka adı gerekli.';
    return null;
  }

  static String? iban(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'IBAN gerekli.';
    if (!Iban.gecerliMi(metin)) {
      return 'IBAN geçersiz. TR ile başlayan 26 hane girin.';
    }
    return null;
  }
}
