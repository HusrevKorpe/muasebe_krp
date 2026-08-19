import 'package:fidancari/domain/cari/cari_grubu.dart';
import 'package:fidancari/domain/cari/cari_suzgeci.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sunucuGrubu', () {
    test('yalnızca fidancı listesi sunucuda süzülür', () {
      expect(CariSuzgeci.fidancilar.sunucuGrubu, CariGrubu.fidanci);
    });

    test('müşteri listesine sunucu süzgeci konmaz', () {
      // `grup == 'musteri'` sorgusu, alanı hiç yazılmamış eski belgeleri
      // eşleştirmez ve bu özellikten önceki herkesi listeden düşürürdü.
      expect(CariSuzgeci.musteriler.sunucuGrubu, isNull);
    });

    test('açık hesap sekmesi grup gözetmez', () {
      expect(CariSuzgeci.acikHesap.sunucuGrubu, isNull);
    });

    test('kaldırılanlar listesi grup gözetmez', () {
      expect(CariSuzgeci.pasifler.sunucuGrubu, isNull);
    });
  });

  group('kayitGirerMi', () {
    test('müşteri listesi fidancıları eler', () {
      expect(CariSuzgeci.musteriler.kayitGirerMi(CariGrubu.musteri), isTrue);
      expect(CariSuzgeci.musteriler.kayitGirerMi(CariGrubu.fidanci), isFalse);
    });

    test('fidancı listesi sunucuda süzüldüğü için elde ayıklamaz', () {
      for (final grup in CariGrubu.values) {
        expect(CariSuzgeci.fidancilar.kayitGirerMi(grup), isTrue);
      }
    });

    test('açık hesap sekmesi iki grubu birlikte gösterir', () {
      for (final grup in CariGrubu.values) {
        expect(CariSuzgeci.acikHesap.kayitGirerMi(grup), isTrue);
      }
    });

    test('kaldırılanlar listesi iki grubu birlikte gösterir', () {
      for (final grup in CariGrubu.values) {
        expect(CariSuzgeci.pasifler.kayitGirerMi(grup), isTrue);
      }
    });
  });

  test('acikHesapMi yalnızca açık hesap sekmesinde doğru', () {
    expect(CariSuzgeci.acikHesap.acikHesapMi, isTrue);
    expect(CariSuzgeci.musteriler.acikHesapMi, isFalse);
    expect(CariSuzgeci.fidancilar.acikHesapMi, isFalse);
    expect(CariSuzgeci.pasifler.acikHesapMi, isFalse);
  });

  test('pasifMi yalnızca kaldırılanlar listesinde doğru', () {
    // Sorgudaki `aktif` eşitliğinin değeri bundan çıkıyor; sekmelerin hiçbiri
    // pasif kayıt getirmemeli.
    expect(CariSuzgeci.pasifler.pasifMi, isTrue);
    expect(CariSuzgeci.musteriler.pasifMi, isFalse);
    expect(CariSuzgeci.fidancilar.pasifMi, isFalse);
    expect(CariSuzgeci.acikHesap.pasifMi, isFalse);
  });

  test('gruplarKarisikMi yalnızca karma listelerde doğru', () {
    // Satırdaki "Fidancı" rozeti buna bakıyor.
    expect(CariSuzgeci.acikHesap.gruplarKarisikMi, isTrue);
    expect(CariSuzgeci.pasifler.gruplarKarisikMi, isTrue);
    expect(CariSuzgeci.musteriler.gruplarKarisikMi, isFalse);
    expect(CariSuzgeci.fidancilar.gruplarKarisikMi, isFalse);
  });
}
