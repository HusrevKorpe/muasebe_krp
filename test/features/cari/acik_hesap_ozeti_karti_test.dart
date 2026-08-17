import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidancari/app/tasarim/tema.dart';
import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/cari/acik_hesap_ozeti.dart';
import 'package:fidancari/features/cari/view/widget/acik_hesap_ozeti_karti.dart';

/// Kart, yüksekliği sınırsız bir bağlamda çiziliyor mu.
///
/// Regresyon: kartın içindeki satır `CrossAxisAlignment.stretch` kullanıyor.
/// Kart, "Açık Hesaplar" sekmesinde bir `Column`un esnek olmayan ilk çocuğu —
/// yani gelen dikey kısıt sonsuz. Stretch onu olduğu gibi çocuklara dayatınca
/// layout "BoxConstraints forces an infinite height" ile patlıyor, ardından
/// her karede `!semantics.parentDataDirty` assertion'ı atılıyordu.
/// Sekme veri geldiği anda kullanılamaz hâle geliyordu.
void main() {
  Future<void> kartiCiz(WidgetTester tester, AcikHesapOzeti ozet) {
    return tester.pumpWidget(
      MaterialApp(
        theme: Tema.acik(),
        home: Scaffold(
          // Ekrandaki yerleşimin aynısı: kart, `Expanded` olmayan bir çocuk
          // olarak `Column`un başında duruyor.
          body: Column(
            children: <Widget>[
              AcikHesapOzetiKarti(ozet: ozet, eksikVar: true),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('sinirsiz yukseklikte tek toplamla cizilir', (tester) async {
    // Erişilebilirlik açıkken semantik ağacı da kuruluyor; hatanın ikinci
    // yüzü orada görünüyordu.
    final semantik = tester.ensureSemantics();

    await kartiCiz(
      tester,
      const AcikHesapOzeti(
        adet: 3,
        alacak: Kurus(1250000),
        borc: Kurus.sifir,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('3 açık hesap'), findsOneWidget);

    semantik.dispose();
  });

  testWidgets('alacak ve borc birlikteyken cizilir', (tester) async {
    final semantik = tester.ensureSemantics();

    await kartiCiz(
      tester,
      const AcikHesapOzeti(
        adet: 5,
        alacak: Kurus(1250000),
        borc: Kurus(430000),
      ),
    );

    expect(tester.takeException(), isNull);
    // Ayırıcı çizgi iki toplam kutusunun yüksekliği kadar uzuyor mu:
    // `IntrinsicHeight` kaldırılırsa bu satır ya patlar ya sıfır yükseklik verir.
    final cizgi = tester.getSize(
      find.descendant(
        of: find.byType(AcikHesapOzetiKarti),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.constraints?.maxWidth == 1,
        ),
      ),
    );
    expect(cizgi.height, greaterThan(0));
    expect(cizgi.height, lessThan(200));

    semantik.dispose();
  });
}
