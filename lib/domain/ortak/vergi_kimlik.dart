/// Vergi kimlik numarası (VKN) ve T.C. kimlik numarası (TCKN) doğrulaması.
///
/// Bir cari hem şahıs hem firma olabilir: şahısta 11 haneli TCKN, firmada
/// 10 haneli VKN kullanılır. İkisi de aynı alanda tutulur; ekstre başlığında
/// zaten tek satır olarak basılacaklar.
///
/// Her iki numaranın da kendi kontrol hanesi vardır. Sadece hane sayısına
/// bakmak yazım hatasını yakalamaz — yanlış vergi numarası basılmış bir ekstre
/// muhasebede sorun çıkarır, bu yüzden kontrol hanesi de doğrulanır.
abstract final class VergiKimlik {
  /// Firma vergi kimlik numarası hane sayısı.
  static const int vknUzunlugu = 10;

  /// T.C. kimlik numarası hane sayısı.
  static const int tcknUzunlugu = 11;

  /// Rakam dışındaki her şeyi atar: `'123 456 78 90'` → `'1234567890'`
  static String normalize(String metin) => metin.replaceAll(RegExp(r'\D'), '');

  /// Numara VKN veya TCKN olarak geçerliyse `true`.
  static bool gecerliMi(String metin) {
    final rakamlar = normalize(metin);
    return switch (rakamlar.length) {
      vknUzunlugu => vknGecerliMi(rakamlar),
      tcknUzunlugu => tcknGecerliMi(rakamlar),
      _ => false,
    };
  }

  /// 10 haneli vergi kimlik numarası kontrol hanesi doğrulaması.
  ///
  /// İlk dokuz hane sırasına göre ağırlıklandırılır, dokuzuncu hanenin ötesinde
  /// kalan toplamın onluk tümleyeni son haneye eşit olmalıdır.
  static bool vknGecerliMi(String rakamlar) {
    if (rakamlar.length != vknUzunlugu) return false;
    final haneler = _haneler(rakamlar);
    if (haneler == null) return false;

    var toplam = 0;
    for (var sira = 0; sira < 9; sira++) {
      final ara = (haneler[sira] + (9 - sira)) % 10;
      if (ara == 0) {
        toplam += 9;
        continue;
      }
      final carpim = (ara * (1 << (9 - sira))) % 9;
      toplam += carpim == 0 ? 9 : carpim;
    }

    return (10 - (toplam % 10)) % 10 == haneler[9];
  }

  /// 11 haneli T.C. kimlik numarası doğrulaması.
  ///
  /// İlk hane sıfır olamaz; 10. hane tek ve çift sıralı hanelerden, 11. hane
  /// ilk on hanenin toplamından türetilir.
  static bool tcknGecerliMi(String rakamlar) {
    if (rakamlar.length != tcknUzunlugu) return false;
    final haneler = _haneler(rakamlar);
    if (haneler == null || haneler.first == 0) return false;

    final tekSiraliToplam =
        haneler[0] + haneler[2] + haneler[4] + haneler[6] + haneler[8];
    final ciftSiraliToplam = haneler[1] + haneler[3] + haneler[5] + haneler[7];

    // Dart'ta `%` pozitif bölende daima pozitif kalan verir; çıkarma negatife
    // düşse bile ayrıca düzeltmeye gerek yok.
    final onuncuHane = ((tekSiraliToplam * 7) - ciftSiraliToplam) % 10;
    if (onuncuHane != haneler[9]) return false;

    final ilkOnHaneToplami = haneler
        .take(10)
        .fold(0, (toplam, hane) => toplam + hane);
    return ilkOnHaneToplami % 10 == haneler[10];
  }

  static List<int>? _haneler(String rakamlar) {
    final haneler = <int>[];
    for (final kod in rakamlar.codeUnits) {
      final hane = kod - 0x30;
      if (hane < 0 || hane > 9) return null;
      haneler.add(hane);
    }
    return haneler;
  }
}
