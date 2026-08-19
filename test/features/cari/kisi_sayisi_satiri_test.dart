import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidancari/app/tasarim/tema.dart';
import 'package:fidancari/features/cari/view/widget/kisi_sayisi_satiri.dart';

/// Liste başındaki kişi sayısı.
///
/// Sayı sunucudan tam geldiğinde olduğu gibi yazılıyor; yalnızca yüklenmiş
/// kayıtlardan geliyorsa "+" ile — kullanıcı eksik bir sayıyı tam sanmamalı.
void main() {
  Future<void> satiriCiz(
    WidgetTester tester, {
    required int adet,
    bool enAz = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: Tema.acik(),
        home: Scaffold(body: KisiSayisiSatiri(adet: adet, enAz: enAz)),
      ),
    );
  }

  testWidgets('tam sayi oldugu gibi yazilir', (tester) async {
    await satiriCiz(tester, adet: 128);

    expect(tester.takeException(), isNull);
    expect(find.text('128 kişi'), findsOneWidget);
  });

  testWidgets('eksik sayi arti isaretiyle yazilir', (tester) async {
    await satiriCiz(tester, adet: 25, enAz: true);

    expect(find.text('25+ kişi'), findsOneWidget);
  });
}
