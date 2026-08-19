import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidancari/app/tasarim/tema.dart';
import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/data/cari/cari_kaydi.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/features/cari/view/widget/cari_satiri.dart';

/// Satırın başındaki sıra numarası.
///
/// Kullanıcının isteği: *"1-2-3 diye sıralasın herkesi."* Numara listedeki
/// yerdir; kayda ait bir alan değil, satırın kendisine verilir.
void main() {
  Future<void> satiriCiz(WidgetTester tester, {required int sira}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: Tema.acik(),
        home: Scaffold(
          body: CariSatiri(
            kayit: const CariKaydi(
              cari: Cari(id: 'a1', ad: 'Bolat Mutlu', bakiye: Kurus(52000000)),
            ),
            sira: sira,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('sira numarasi adin solunda basilir', (tester) async {
    await satiriCiz(tester, sira: 7);

    expect(tester.takeException(), isNull);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Bolat Mutlu'), findsOneWidget);

    // Numara baş harf karesinin solunda: kullanıcı listeyi yukarıdan aşağı
    // sayarken gözü tek bir sütunda kalmalı.
    final numara = tester.getTopLeft(find.text('7'));
    final ad = tester.getTopLeft(find.text('Bolat Mutlu'));
    expect(numara.dx, lessThan(ad.dx));
  });

  testWidgets('uc haneli numara adin hizasini kaydirmaz', (tester) async {
    // Sütun sabit genişlikte; 7. satırla 128. satırın adı aynı yerden
    // başlamazsa liste kaydırıldıkça sallanır.
    await satiriCiz(tester, sira: 7);
    final tekHane = tester.getTopLeft(find.text('Bolat Mutlu')).dx;

    await satiriCiz(tester, sira: 128);
    expect(tester.getTopLeft(find.text('Bolat Mutlu')).dx, tekHane);
  });
}
