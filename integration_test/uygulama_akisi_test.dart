import 'package:fidancari/app/uygulama.dart';
import 'package:fidancari/core/metin/metinler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

/// Faz 1 kabul kriterlerinin uçtan uca doğrulaması.
///
/// Repository testleri veri katmanını ayrı ayrı sınıyor; buradaki akış
/// yönlendiricinin iki kapısını (oturum ve kurulum) ve ekranların birbirine
/// bağlanmasını sınar — parçalar tek tek doğru olup birleşince yanlış
/// davranabilir.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(emulatoreBaglan);

  testWidgets('kurulumdan cari aramaya tam akış', (tester) async {
    // Form yedi alanlı; uzun bir yüzeyde tamamı görünür olsun ki testin her
    // adımı kaydırma hilelerine boğulmasın.
    tester.view
      ..physicalSize = const Size(1200, 3400)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await FirebaseAuth.instance.signOut();
    await yeniKullaniciAc(FirebaseAuth.instance);

    await tester.pumpWidget(
      const ProviderScope(child: FidanCariUygulamasi()),
    );
    await _dinlen(tester);

    // ── Kriter 2: ilk açılışta işletme bilgileri soruluyor ────────────────
    expect(
      find.text(Metinler.kurulumHosGeldiniz),
      findsOneWidget,
      reason: 'yeni kullanıcı kurulum ekranına düşmeli',
    );

    await _doldur(tester, Metinler.isletmeAdi, 'Favori Fidancılık');
    await _doldur(tester, Metinler.adres, 'Sarıçam / ADANA');
    await _doldur(tester, Metinler.telefon, '0322 000 00 00');
    await _doldur(tester, Metinler.vergiDairesi, 'Yüreğir');
    await _doldur(tester, Metinler.vergiNo, '1234567899');

    await tester.tap(
      find.widgetWithText(FilledButton, Metinler.kurulumTamamla),
    );
    await _dinlen(tester);

    // Kurulum tamamlanınca yönlendirici ana ekrana taşır.
    expect(find.text(Metinler.cariler), findsOneWidget);
    expect(
      find.text(Metinler.cariYokBaslik),
      findsOneWidget,
      reason: 'yeni işletmede boş durum ekranı görünmeli',
    );

    // ── Kriter 3: cari eklenebiliyor ve listede görünüyor ─────────────────
    await tester.tap(find.widgetWithText(FilledButton, Metinler.cariEkle));
    await _dinlen(tester);

    await _doldur(tester, Metinler.cariAdi, 'İstanbul Fidancılık');
    // Cari formunda isteğe bağlı alanların etiketine bu ek geliyor.
    await _doldur(
      tester,
      '${Metinler.sehir} (${Metinler.istegeBagli})',
      'İstanbul',
    );
    await tester.tap(find.widgetWithText(FilledButton, Metinler.kaydet));
    await _dinlen(tester);

    expect(find.text('İstanbul Fidancılık'), findsOneWidget);

    // ── Kriter 4: Türkçe arama tuzağı ─────────────────────────────────────
    // "İstanbul" kaydı, ı/i ayrımını bozan yazımlarla da bulunmalı.
    for (final yazim in <String>['istanbul', 'İSTANBUL', 'ıstanbul']) {
      await _ara(tester, yazim);
      expect(
        find.text('İstanbul Fidancılık'),
        findsOneWidget,
        reason: '"$yazim" araması sonuç vermeli',
      );
    }

    await _ara(tester, 'zzz');
    expect(find.text(Metinler.aramaSonucuYokBaslik), findsOneWidget);

    await _ara(tester, '');
    expect(find.text('İstanbul Fidancılık'), findsOneWidget);

    // ── Kriter 6: cariye dokununca detay açılıyor ─────────────────────────
    await tester.tap(find.text('İstanbul Fidancılık'));
    await _dinlen(tester);

    expect(find.text(Metinler.bakiye), findsOneWidget);
    expect(
      find.text('0,00 ₺'),
      findsOneWidget,
      reason: 'Faz 1de bakiye sıfır gösterilir',
    );
    expect(find.text(Metinler.bakiyeKapali), findsOneWidget);
    expect(find.text(Metinler.islemYokBaslik), findsOneWidget);
  });
}

/// Etiketiyle bulunan metin alanını doldurur.
Future<void> _doldur(
  WidgetTester tester,
  String etiket,
  String deger,
) async {
  final alan = find.widgetWithText(TextFormField, etiket);
  expect(alan, findsOneWidget, reason: '"$etiket" alanı bulunamadı');
  await tester.enterText(alan, deger);
  await tester.pump();
}

/// Arama kutusuna yazar ve gecikmeli sorgunun tamamlanmasını bekler.
Future<void> _ara(WidgetTester tester, String metin) async {
  await tester.enterText(find.byType(TextField).first, metin);
  await _dinlen(tester);
}

/// Ekranın oturmasını bekler.
///
/// `pumpAndSettle` kullanılamıyor: yükleme göstergesi sürekli dönen bir
/// animasyon olduğu için hiçbir zaman "settle" olmuyor. Bunun yerine sabit
/// sayıda kare ilerletiliyor — arada Firestore ve arama gecikmesi tamamlanır.
Future<void> _dinlen(WidgetTester tester, {int kare = 25}) async {
  for (var sayac = 0; sayac < kare; sayac++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
