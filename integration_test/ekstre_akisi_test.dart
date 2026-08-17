import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/core/metin/metinler.dart';
import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/data/cari/cari_repository.dart';
import 'package:fidancari/data/islem/islem_repository.dart';
import 'package:fidancari/data/isletme/isletme_repository.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:fidancari/domain/islem/islem_tipi.dart';
import 'package:fidancari/domain/isletme/banka_hesabi.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:printing/printing.dart';

import 'emulator_yardimcilari.dart';

/// Faz 4'ün uçtan uca doğrulaması: cari detayından ekstre önizlemesine.
///
/// Asıl sınanan, `printing` eklentisinin cihazda gerçekten çalışıp çalışmadığı.
/// PDF üretimi saf Dart olduğu için birim testiyle doğrulanabiliyor; ama
/// önizlemenin sayfayı **rasterlemesi** platform kanalından geçiyor ve ancak
/// burada görülebiliyor. Ekstre paylaşılamıyorsa fazın hiçbir anlamı yok.
///
/// Veri, uygulamanın baktığı yere — ortak deftere — serpiliyor; oturumun `uid`
/// değeri artık bir yol parçası değil. Defter ortak olduğu için önceki koşuların
/// kayıtları burada karşımıza çıkar ve "İğde Tarım" ikinci kez bulunurdu; o
/// yüzden emulator verisi baştan siliniyor.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await emulatoreBaglan();
    await firestoreVerisiniSil();
  });

  testWidgets('cari detayından ekstre önizlemesine', (tester) async {
    tester.view
      ..physicalSize = const Size(1400, 3000)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await FirebaseAuth.instance.signOut();
    await yeniKullaniciAc(FirebaseAuth.instance);

    const isletmeId = Isletme.ortakId;
    final firestore = FirebaseFirestore.instance;

    // ── Ekstrenin beslendiği veri: işletme, cari ve iki işlem ─────────────
    await IsletmeRepository(
      firestore: firestore,
      isletmeId: isletmeId,
    ).kaydet(
      const Isletme(
        id: isletmeId,
        ad: 'Favori Fidancılık',
        unvan: 'Tar.Taş.Hay.Ltd.Şti',
        adres: 'Sarıçam / ADANA',
        telefon: '0322 000 00 00',
        bankaHesaplari: <BankaHesabi>[
          BankaHesabi(
            banka: 'Ziraat Bankası',
            iban: 'TR000000000000000000000001',
          ),
        ],
      ),
    );

    final cariRepository = CariRepository(
      firestore: firestore,
      isletmeId: isletmeId,
    );
    final cariId = await cariRepository.ekle(
      const Cari(id: '', ad: 'İğde Tarım', sehir: 'Isparta'),
    );

    final islemRepository = IslemRepository(
      firestore: firestore,
      isletmeId: isletmeId,
    );
    await islemRepository.ekle(
      cariId: cariId,
      islem: Islem.fatura(
        tip: IslemTipi.satisFaturasi,
        baslik: 'Şeftali-Ayçiçeği',
        islemTarihi: DateTime(2025, 3, 8),
        kalemler: <IslemKalemi>[
          IslemKalemi.birimFiyattan(
            tur: 'şeftali',
            miktar: 1200,
            birimFiyat: Kurus.liradan(38, 50),
          ),
        ],
      ),
    );
    await islemRepository.ekle(
      cariId: cariId,
      islem: Islem.odeme(
        tip: IslemTipi.tahsilat,
        baslik: Metinler.musteridenTahsilat,
        islemTarihi: DateTime(2025, 4, 2),
        tutar: Kurus.liradan(20000),
      ),
    );

    await tester.pumpWidget(await uygulamayiKur());
    await _dinlen(tester);

    // ── Cari detayı ───────────────────────────────────────────────────────
    await tester.tap(find.text('İğde Tarım'));
    await _dinlen(tester);
    expect(find.text(Metinler.bakiye), findsOneWidget);

    // ── Kısayol: "Ekstre Al" ──────────────────────────────────────────────
    final ekstreDugmesi = find.byTooltip(Metinler.ekstreAl);
    expect(ekstreDugmesi, findsOneWidget, reason: 'kısayol görünmeli');

    await tester.tap(ekstreDugmesi);
    await _dinlen(tester);

    expect(find.text(Metinler.ekstre), findsOneWidget);
    expect(find.text(Metinler.aralikTumu), findsOneWidget);
    expect(find.text(Metinler.aralikBuYil), findsOneWidget);

    // ── Önizleme: PDF üretilip cihazda rasterlendi mi? ────────────────────
    await _dinlen(tester, kare: 60);

    expect(tester.takeException(), isNull, reason: 'önizleme hata vermemeli');
    expect(
      find.byType(PdfPreview),
      findsOneWidget,
      reason: 'PDF önizlemesi açılmalı',
    );
    expect(
      find.text(Metinler.ekstreUretiliyor),
      findsNothing,
      reason: 'üretim tamamlanmış olmalı',
    );
    expect(
      find.text(Metinler.ekstreUretilemedi),
      findsNothing,
      reason: 'ekstre hatasız üretilmeli',
    );

    // ── Aralık değiştirme ekstreyi yeniden üretir ─────────────────────────
    await tester.tap(find.text(Metinler.aralikBuYil));
    await _dinlen(tester, kare: 60);

    expect(tester.takeException(), isNull);
    expect(find.byType(PdfPreview), findsOneWidget);
  });
}

/// Ekranın oturmasını bekler.
///
/// `pumpAndSettle` kullanılamıyor: yükleme göstergesi sürekli döndüğü için
/// hiçbir zaman "settle" olmuyor (bkz. `uygulama_akisi_test.dart`).
Future<void> _dinlen(WidgetTester tester, {int kare = 25}) async {
  for (var sayac = 0; sayac < kare; sayac++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
