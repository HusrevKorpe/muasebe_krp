import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/islem/islem_basligi.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IslemKalemi kalem(String ad) => IslemKalemi.birimFiyattan(
    tur: ad,
    miktar: 1,
    birimFiyat: Kurus.liradan(10),
  );

  List<IslemKalemi> kalemler(List<String> adlar) =>
      adlar.map(kalem).toList(growable: false);

  group('yazılan açıklama varsa', () {
    test('olduğu gibi kullanılır', () {
      expect(
        IslemBasligi.uret(
          yazilan: 'Zeytin-Hurma',
          kalemler: kalemler(<String>['zeytin', 'Hurma']),
        ),
        'Zeytin-Hurma',
      );
    });

    test('baştaki ve sondaki boşluk kırpılır', () {
      expect(
        IslemBasligi.uret(yazilan: '  Zeytin  ', kalemler: kalemler(<String>[])),
        'Zeytin',
      );
    });
  });

  group('açıklama boşsa kalemlerden üretilir', () {
    test('tek kalem adı yazılır', () {
      expect(
        IslemBasligi.uret(yazilan: '', kalemler: kalemler(<String>['zeytin'])),
        'zeytin',
      );
    });

    test('üç kaleme kadar hepsi yazılır', () {
      expect(
        IslemBasligi.uret(
          yazilan: '',
          kalemler: kalemler(<String>['zeytin', 'Hurma', 'nakliye']),
        ),
        'zeytin, Hurma, nakliye',
      );
    });

    test('üçten fazlası sayıyla özetlenir', () {
      expect(
        IslemBasligi.uret(
          yazilan: '',
          kalemler: kalemler(<String>[
            'elma',
            'armut',
            'kiraz',
            'ayva',
            'asma',
          ]),
        ),
        'elma, armut, kiraz +2',
      );
    });

    test('yalnızca boşluktan ibaret açıklama da boş sayılır', () {
      expect(
        IslemBasligi.uret(
          yazilan: '   ',
          kalemler: kalemler(<String>['zeytin']),
        ),
        'zeytin',
      );
    });

    test('adsız kalemler atlanır', () {
      expect(
        IslemBasligi.uret(
          yazilan: '',
          kalemler: kalemler(<String>['', 'zeytin', '  ']),
        ),
        'zeytin',
      );
    });

    test('kalem yoksa boş döner', () {
      expect(IslemBasligi.uret(yazilan: '', kalemler: kalemler(<String>[])), '');
    });
  });

  // Düzenleme formu açıklama kutusunu buna bakarak dolduruyor: türetilmiş
  // başlık kutuya yazılmaz ki satır değişince başlık da yenilensin.
  group('turetilmisMi', () {
    test('kalemlerden üretilen başlığı tanır', () {
      expect(
        IslemBasligi.turetilmisMi(
          baslik: 'zeytin, Hurma',
          kalemler: kalemler(<String>['zeytin', 'Hurma']),
        ),
        isTrue,
      );
    });

    test('kullanıcının yazdığı başlığı türetilmiş saymaz', () {
      expect(
        IslemBasligi.turetilmisMi(
          baslik: 'Zeytin-Hurma',
          kalemler: kalemler(<String>['zeytin', 'Hurma']),
        ),
        isFalse,
      );
    });

    test('özetlenmiş uzun başlık da türetilmiş sayılır', () {
      expect(
        IslemBasligi.turetilmisMi(
          baslik: 'elma, armut, kiraz +2',
          kalemler: kalemler(<String>[
            'elma',
            'armut',
            'kiraz',
            'ayva',
            'asma',
          ]),
        ),
        isTrue,
      );
    });

    test('kalemsiz kayıtta yalnızca boş başlık türetilmiş sayılır', () {
      expect(
        IslemBasligi.turetilmisMi(baslik: '', kalemler: kalemler(<String>[])),
        isTrue,
      );
      expect(
        IslemBasligi.turetilmisMi(
          baslik: 'Müşteriden Tahsilat',
          kalemler: kalemler(<String>[]),
        ),
        isFalse,
      );
    });
  });
}
