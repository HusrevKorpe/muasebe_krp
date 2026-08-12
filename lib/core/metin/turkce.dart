/// Türkçe metin işlemleri: küçük harf dönüşümü, arama ve sıralama anahtarları.
///
/// Dart'ın yerleşik büyük/küçük harf dönüşümü Türkçe için hatalıdır. Dart, `i`
/// harfini noktasız `ı` ile eşleştirmez; ikisini de tek bir `i`/`I` çiftine indirger:
///
/// - `'I'.toLowerCase()` → `'i'` — Türkçe'de `'ı'` olmalıdır.
///   Sonuç: `"ISPARTA".toLowerCase() != "ısparta"`, arama tutmaz.
/// - `'i'.toUpperCase()` → `'I'` — Türkçe'de `'İ'` olmalıdır.
///   Sonuç: `"izmir".toUpperCase()` → `"IZMIR"`, başlık yanlış görünür.
///
/// Bu yüzden arama ve sıralama daima bu dosyadaki fonksiyonlardan geçer.
/// Ekranlarda doğrudan `toLowerCase()` çağrılmaz — bkz. KURALLAR.md §6.1.
library;

/// Arama karşılaştırması için harf katlama tablosu.
/// Türkçe'ye özgü harfler ASCII karşılıklarına indirgenir ki
/// "İstanbul", "ISTANBUL", "ıstanbul" ve "istanbul" aynı anahtarı üretsin.
const Map<String, String> _aramaKatlamasi = {
  'ç': 'c', 'Ç': 'c',
  'ğ': 'g', 'Ğ': 'g',
  'ı': 'i', 'I': 'i', 'İ': 'i',
  'ö': 'o', 'Ö': 'o',
  'ş': 's', 'Ş': 's',
  'ü': 'u', 'Ü': 'u',
  'â': 'a', 'Â': 'a',
  'î': 'i', 'Î': 'i',
  'û': 'u', 'Û': 'u',
};

/// Türkçe kurallarına uyan küçük harf dönüşümü.
/// `'IĞDIR'` → `'ığdır'`, `'İZMİR'` → `'izmir'`
String turkceKucuk(String metin) {
  final tampon = StringBuffer();
  for (final kod in metin.runes) {
    final karakter = String.fromCharCode(kod);
    if (karakter == 'I') {
      tampon.write('ı');
    } else if (karakter == 'İ') {
      tampon.write('i');
    } else {
      tampon.write(karakter.toLowerCase());
    }
  }
  return tampon.toString();
}

/// Türkçe kurallarına uyan büyük harf dönüşümü.
/// `'ığdır'` → `'IĞDIR'`, `'izmir'` → `'İZMİR'`
String turkceBuyuk(String metin) {
  final tampon = StringBuffer();
  for (final kod in metin.runes) {
    final karakter = String.fromCharCode(kod);
    if (karakter == 'i') {
      tampon.write('İ');
    } else if (karakter == 'ı') {
      tampon.write('I');
    } else {
      tampon.write(karakter.toUpperCase());
    }
  }
  return tampon.toString();
}

/// İlk harfi Türkçe kurallarına göre büyütür, kalanına dokunmaz.
/// `'adet'` → `'Adet'`, `'ışık'` → `'Işık'`
String ilkHarfBuyuk(String metin) {
  if (metin.isEmpty) return metin;
  final ilk = String.fromCharCode(metin.runes.first);
  return turkceBuyuk(ilk) + metin.substring(ilk.length);
}

/// Arama için normalize edilmiş anahtar üretir.
///
/// Türkçe harfler ASCII'ye katlanır, harfler küçültülür, baştaki/sondaki boşluk
/// atılır ve aradaki çoklu boşluklar teke indirilir.
///
/// Firestore'da `aramaAnahtari` alanına bu değer yazılır; kullanıcının yazdığı
/// arama metni de aynı fonksiyondan geçirilerek karşılaştırılır.
///
/// `'  İSTANBUL   Fidancılık '` → `'istanbul fidancilik'`
String aramaAnahtari(String metin) {
  final tampon = StringBuffer();
  for (final kod in metin.runes) {
    final karakter = String.fromCharCode(kod);
    tampon.write(_aramaKatlamasi[karakter] ?? karakter.toLowerCase());
  }
  return tampon.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Türk alfabesi sırasına uyan sıralama anahtarı.
///
/// Her harf iki karakterlik bir koda çevrilir; böylece basit metin
/// karşılaştırması Türkçe sırayı verir: `c < ç`, `g < ğ`, `ı < i`,
/// `o < ö`, `s < ş`, `u < ü`.
const Map<String, String> _siralamaKodlari = {
  'c': 'c0', 'ç': 'c1',
  'g': 'g0', 'ğ': 'g1',
  'ı': 'i0', 'i': 'i1',
  'o': 'o0', 'ö': 'o1',
  's': 's0', 'ş': 's1',
  'u': 'u0', 'ü': 'u1',
};

/// [turkceKarsilastir] için sıralama anahtarı üretir.
String siralamaAnahtari(String metin) {
  final kucuk = turkceKucuk(metin);
  final tampon = StringBuffer();
  for (final kod in kucuk.runes) {
    final karakter = String.fromCharCode(kod);
    final siralamaKodu = _siralamaKodlari[karakter];
    tampon.write(siralamaKodu ?? '${karakter}0');
  }
  return tampon.toString();
}

/// İki metni Türk alfabesi sırasına göre karşılaştırır.
/// `list.sort(turkceKarsilastir)` biçiminde kullanılır.
int turkceKarsilastir(String a, String b) =>
    siralamaAnahtari(a).compareTo(siralamaAnahtari(b));
