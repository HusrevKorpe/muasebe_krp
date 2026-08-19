import 'package:fidancari/domain/cari/cari_grubu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('anahtardan', () {
    test('bilinen anahtarlar kendi grubuna çevrilir', () {
      expect(CariGrubu.anahtardan('musteri'), CariGrubu.musteri);
      expect(CariGrubu.anahtardan('fidanci'), CariGrubu.fidanci);
    });

    test('alanı olmayan belge müşteri sayılır', () {
      // Bu özellikten önce kaydedilmiş her kişide `grup` alanı yok; hepsi
      // müşteri olarak açılmalı (kullanıcının kararı).
      expect(CariGrubu.anahtardan(null), CariGrubu.musteri);
    });

    test('tanınmayan değer müşteri sayılır', () {
      // İleride bir grup daha eklenip geri alınırsa eski belge patlamamalı.
      expect(CariGrubu.anahtardan('tedarikci'), CariGrubu.musteri);
      expect(CariGrubu.anahtardan(''), CariGrubu.musteri);
    });
  });

  test('anahtarlar Firestore değeriyle birebir', () {
    // Anahtar veritabanına yazılıyor; değişirse geçmiş kayıtlar sessizce
    // müşteriye düşer (bkz. `IslemTipi.anahtar`).
    expect(CariGrubu.musteri.anahtar, 'musteri');
    expect(CariGrubu.fidanci.anahtar, 'fidanci');
  });

  test('varsayılan grup müşteri', () {
    expect(CariGrubu.varsayilan, CariGrubu.musteri);
  });

  test('fidanciMi yalnızca fidancıda doğru', () {
    expect(CariGrubu.fidanci.fidanciMi, isTrue);
    expect(CariGrubu.musteri.fidanciMi, isFalse);
  });
}
