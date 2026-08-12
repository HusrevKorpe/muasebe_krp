import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/data/firebase/firestore_donusum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Domain modelleri Firestore tiplerini tanımıyor (KURALLAR.md §1.3); dönüşüm
/// tam bu sınırda yapılıyor. Burada kaçan bir [Timestamp] modelde sessizce
/// `null` tarih olarak okunur — o yüzden iç içe yapılar da sınanıyor.
///
/// [Timestamp.toDate] **yerel saatli** bir [DateTime] üretir; bu bilinçli:
/// ekranda "17 Eylül 2021" yazarken kullanıcının kendi takvim günü görünmeli.
/// Bu yüzden karşılaştırmalar anlık üzerinden yapılıyor, `==` ile değil.
void main() {
  final tarih = DateTime.utc(2021, 9, 17, 12, 30);

  test('kök seviyedeki Timestamp DateTime olur', () {
    final sonuc = firestoreHaritasi(<String, Object?>{
      'ad': 'Ahmet',
      'olusturmaTarihi': Timestamp.fromDate(tarih),
    });

    expect(sonuc['ad'], 'Ahmet');
    expect(sonuc['olusturmaTarihi'], isA<DateTime>());
    expect((sonuc['olusturmaTarihi']! as DateTime).isAtSameMomentAs(tarih),
        isTrue);
  });

  test('dizi içindeki haritalarda da çevrilir', () {
    final sonuc = firestoreHaritasi(<String, Object?>{
      'bankaHesaplari': <Object?>[
        <String, Object?>{
          'banka': 'Ziraat',
          'eklenme': Timestamp.fromDate(tarih),
        },
      ],
    });

    final hesaplar = sonuc['bankaHesaplari']! as List<Object?>;
    final ilk = hesaplar.first! as Map<String, Object?>;
    expect((ilk['eklenme']! as DateTime).isAtSameMomentAs(tarih), isTrue);
  });

  test('gömülü haritada da çevrilir', () {
    final sonuc = firestoreHaritasi(<String, Object?>{
      'ic': <String, Object?>{'tarih': Timestamp.fromDate(tarih)},
    });

    final ic = sonuc['ic']! as Map<String, Object?>;
    expect((ic['tarih']! as DateTime).isAtSameMomentAs(tarih), isTrue);
  });

  test('null belge boş harita döner', () {
    expect(firestoreHaritasi(null), isEmpty);
  });

  test('diğer tipler olduğu gibi kalır', () {
    final sonuc = firestoreHaritasi(<String, Object?>{
      'bakiyeKurus': 9400000,
      'aktif': true,
      'notlar': null,
    });

    expect(sonuc['bakiyeKurus'], 9400000);
    expect(sonuc['aktif'], isTrue);
    expect(sonuc['notlar'], isNull);
  });
}
