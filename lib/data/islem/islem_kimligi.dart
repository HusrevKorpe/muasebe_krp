/// Zaman sıralı Firestore belge kimliği üretir.
///
/// Firestore'un kendi ürettiği kimlikler rastgeledir. İşlem sıralaması
/// `(islemTarihi, __name__)` ölçütüne dayandığı için (bkz.
/// `domain/islem/islem_siralamasi.dart`), **aynı güne düşen** iki işlemin
/// sırası rastgele kimlikle belirlenirse ekstre satırları giriş sırasından
/// başka türlü dizilir. Referans ekstrede bu durum var: 17 Eylül 2021'de önce
/// fatura, sonra tahsilat işlenmiş; ters dizilirse ara bakiye tutmaz.
///
/// `serverTimestamp()` bu işi göremez: sunucu onaylayana kadar `null` okunur ve
/// çevrimdışı girilen işlem listede yerini bulamaz (bkz. KURALLAR.md §4.4).
///
/// Üretilen kimlik iki parçadır:
/// - 11 hane: mikrosaniye zaman damgası, 36 tabanında, başı sıfırla dolu
/// - 6 hane: rastgele son ek — aynı mikrosaniyede iki kayıt çakışmasın diye
///
/// 36 tabanı yalnızca `0-9a-z` üretir; Firestore belge kimliklerini UTF-8 bayt
/// sırasına göre dizdiği için sıralama Dart'ın metin karşılaştırmasıyla birebir
/// aynı sonucu verir.
library;

import 'dart:math';

const int _zamanHaneSayisi = 11;
const int _rastgeleHaneSayisi = 6;
const String _alfabe = '0123456789abcdefghijklmnopqrstuvwxyz';

final Random _rastgele = Random();

/// [an] verilmezse cihaz saati kullanılır.
///
/// Cihaz saati geri alınırsa aynı gün içindeki sıralama bozulabilir; bakiyenin
/// **toplamı** bundan etkilenmez, yalnızca aynı güne düşen iki satırın sırası
/// değişir.
String yeniIslemKimligi({DateTime? an}) {
  final mikrosaniye = (an ?? DateTime.now()).microsecondsSinceEpoch;
  final zaman = mikrosaniye
      .toRadixString(36)
      .padLeft(_zamanHaneSayisi, '0');

  final sonEk = String.fromCharCodes(<int>[
    for (var hane = 0; hane < _rastgeleHaneSayisi; hane++)
      _alfabe.codeUnitAt(_rastgele.nextInt(_alfabe.length)),
  ]);

  return '$zaman$sonEk';
}
