import 'package:fidancari/app/uygulama.dart';
import 'package:fidancari/core/metin/metinler.dart';
import 'package:fidancari/domain/islem/islem_tipi.dart';
import 'package:fidancari/features/islem/view/widget/islem_tipi_gorunumu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

/// Uçtan uca akış: açılış → ürün → kişi → satış → bakiye.
///
/// Repository testleri veri katmanını ayrı ayrı sınıyor; buradaki akış
/// yönlendiricinin kapısını, alt sekmeleri ve ekranların birbirine bağlanmasını
/// sınar — parçalar tek tek doğru olup birleşince yanlış davranabilir.
///
/// Giriş ekranı burada sınanmıyor: test açık bir oturumla başlıyor, uygulama da
/// açılışta saklı oturumu bulup doğrudan içeri giriyor.
///
/// Defter ortak olduğu için önceki koşuların kayıtları burada karşımıza çıkar;
/// o yüzden emulator verisi baştan siliniyor.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await emulatoreBaglan();
    await firestoreVerisiniSil();
  });

  testWidgets('açılıştan satışa tam akış', (tester) async {
    // Formlar uzun; geniş bir yüzeyde tamamı görünür olsun ki testin her adımı
    // kaydırma hilelerine boğulmasın.
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

    // ── Açılışta doğrudan kişiler sekmesi ─────────────────────────────────
    //
    // İşletme bilgileri artık sorulmuyor: profil boş da olsa uygulama açılır.
    // "Kişiler" hem başlıkta hem alt sekmede yazıyor.
    expect(find.text(Metinler.cariler), findsNWidgets(2));
    expect(
      find.text(Metinler.cariYokBaslik),
      findsOneWidget,
      reason: 'boş defterde boş durum ekranı görünmeli',
    );

    // ── Alt sekmeler yerinde ──────────────────────────────────────────────
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(Metinler.urunler), findsOneWidget);
    expect(find.text(Metinler.ayarlar), findsOneWidget);

    // ── Ürün ekleme: sattığımız şeyler ────────────────────────────────────
    await tester.tap(find.text(Metinler.urunler));
    await _dinlen(tester);

    expect(find.text(Metinler.urunYokBaslik), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, Metinler.urunEkle));
    await _dinlen(tester);

    await _doldur(tester, Metinler.urunAdi, 'zeytin');
    await _doldur(tester, Metinler.urunFiyati, '7');
    await tester.tap(find.widgetWithText(FilledButton, Metinler.kaydet));
    await _dinlen(tester);

    expect(find.text('zeytin'), findsOneWidget);
    expect(find.text('7,00 ₺'), findsOneWidget);

    // ── Kişi ekleme ───────────────────────────────────────────────────────
    await tester.tap(find.text(Metinler.cariler).last);
    await _dinlen(tester);

    await tester.tap(find.widgetWithText(FilledButton, Metinler.cariEkle));
    await _dinlen(tester);

    await _doldur(tester, Metinler.cariAdi, 'İstanbul Fidancılık');
    // Kişi formunda isteğe bağlı alanların etiketine bu ek geliyor.
    await _doldur(
      tester,
      '${Metinler.sehir} (${Metinler.istegeBagli})',
      'İstanbul',
    );
    await tester.tap(find.widgetWithText(FilledButton, Metinler.kaydet));
    await _dinlen(tester);

    expect(find.text('İstanbul Fidancılık'), findsOneWidget);

    // ── Türkçe arama tuzağı ───────────────────────────────────────────────
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

    // ── Kişiye dokununca sayfası açılıyor ─────────────────────────────────
    await tester.tap(find.text('İstanbul Fidancılık'));
    await _dinlen(tester);

    expect(find.text(Metinler.bakiye), findsOneWidget);
    expect(find.text('0,00 ₺'), findsOneWidget);
    expect(find.text(Metinler.bakiyeKapali), findsOneWidget);
    expect(find.text(Metinler.islemYokBaslik), findsOneWidget);

    // Dört giriş düğmesi tip seçme diyaloğunun yerini aldı.
    for (final tip in IslemTipi.values) {
      expect(
        find.text(tip.ad),
        findsOneWidget,
        reason: '"${tip.ad}" düğmesi kişi sayfasında olmalı',
      );
    }

    // ── "Sattım": tek adımda satış girişi ─────────────────────────────────
    await tester.tap(find.text(IslemTipi.satisFaturasi.ad));
    await _dinlen(tester);

    // Açıklama boş bırakılıyor: başlık kalem adlarından üretilmeli.
    await tester.tap(find.widgetWithText(TextButton, Metinler.kalemEkle));
    await _dinlen(tester);

    await _doldur(tester, Metinler.kalemAdi, 'zeytin');
    await _doldur(tester, Metinler.miktar, '100');
    await _doldur(tester, Metinler.birimFiyat, '7');
    await tester.tap(find.widgetWithText(FilledButton, Metinler.ekle));
    await _dinlen(tester);

    await tester.tap(find.widgetWithText(FilledButton, Metinler.kaydet));
    await _dinlen(tester);

    // Kişi sayfasına dönüldü: bakiye ve kalemden üretilen başlık görünmeli.
    expect(
      find.text('700,00 ₺'),
      findsWidgets,
      reason: '100 × 7,00 ₺ = 700,00 ₺ bakiyeye yazılmalı',
    );
    expect(
      find.text('zeytin'),
      findsOneWidget,
      reason: 'açıklama boş bırakıldı; başlık kalem adından üretilmeli',
    );
    expect(find.text(Metinler.bakiyeCariBorclu), findsOneWidget);
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
