import 'dart:convert';
import 'dart:typed_data';

import 'package:fidancari/core/hata/hatalar.dart';
import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/ekstre/ekstre.dart';
import 'package:fidancari/domain/ekstre/ekstre_araligi.dart';
import 'package:fidancari/domain/ekstre/ekstre_olusturucu.dart';
import 'package:fidancari/domain/islem/bakiye_dokumu.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:fidancari/domain/islem/islem_tipi.dart';
import 'package:fidancari/features/ekstre/view/pdf/ekstre_belgesi.dart';
import 'package:fidancari/features/ekstre/view/pdf/ekstre_fontlari.dart';
import 'package:fidancari/features/ekstre/view/pdf/ekstre_tablosu.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import '../../ornek/ornek_isletme.dart';
import '../../ornek/referans_ekstre.dart';

/// PDF üretiminin doğrulanması.
///
/// Metnin PDF içinde nasıl göründüğü baytlardan okunamaz (yazı, sıkıştırılmış
/// içerik akışında glif numaralarına dönüşür). Bu yüzden Türkçe karakter
/// kontrolü **fontun kendi karakter tablosundan** yapılıyor: gömülen fontta
/// `ğ` yoksa PDF'te o harfin yerine kutucuk çıkar ve ekstre müşteriye
/// gönderilemez (`fazlar/faz-4-ekstre.md`, riskler).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hazirlanma = DateTime(2025, 5, 24);

  Future<Uint8List> uret({
    List<Islem>? islemler,
    EkstreAraligi aralik = const EkstreAraligi.tumu(),
  }) async => EkstreBelgesi.uret(
    ekstre: EkstreOlusturucu.olustur(
      isletme: ornekIsletme,
      cari: ornekCari,
      aralik: aralik,
      islemler: islemler ?? referansIslemleri,
      hazirlanmaTarihi: hazirlanma,
    ),
    fontlar: await EkstreFontlari.yukle(),
  );

  group('Gömülü font — kabul kriteri 4', () {
    /// Ekstrede geçebilecek, `pdf` paketinin yerleşik fontlarında bulunmayan
    /// karakterler. `₺` ve uzun tire de listede: para simgesi ve tarih aralığı
    /// ayracı her ekstrede basılıyor.
    const String zorKarakterler = 'ŞeftaliAyçiçeğiİĞDEğşıİçöüÇÖÜ₺—×·';

    test('Roboto, Türkçe karakterlerin ve ₺ işaretinin tamamını taşır', () async {
      for (final yol in <String>[
        EkstreFontlari.normalYolu,
        EkstreFontlari.kalinYolu,
      ]) {
        final ayristirici = TtfParser(await rootBundle.load(yol));

        for (final kod in zorKarakterler.runes) {
          expect(
            ayristirici.charToGlyphIndexMap.containsKey(kod),
            isTrue,
            reason:
                '${String.fromCharCode(kod)} (U+${kod.toRadixString(16)}) '
                '$yol içinde yok — PDF\'te kutucuk çıkar',
          );
        }
      }
    });

    test('font PDF belgesine gömülür', () async {
      final baytlar = await uret();

      expect(
        _metin(baytlar),
        contains('/FontFile2'),
        reason: 'gömülü TrueType font akışı bulunamadı',
      );
    });
  });

  group('Belge üretimi', () {
    test('geçerli PDF üretir', () async {
      final baytlar = await uret();

      expect(baytlar.length, greaterThan(1000));
      expect(_metin(baytlar).startsWith('%PDF-'), isTrue);
    });

    test('referans ekstrenin dokuz işlemi tek sayfaya sığar', () async {
      expect(_sayfaSayisi(await uret()), 1);
    });

    test('100+ işlemli cari çok sayfalı PDF üretir', () async {
      final baytlar = await uret(islemler: _cokIslem(120));

      expect(_sayfaSayisi(baytlar), greaterThan(1));
    });

    test('hiç işlem yoksa yine PDF üretilir — çökmez', () async {
      final baytlar = await uret(islemler: <Islem>[]);

      expect(baytlar.length, greaterThan(1000));
      expect(_sayfaSayisi(baytlar), 1);
    });

    test('Türkçe karakterli cari ve kalem adlarıyla üretilir', () async {
      final baytlar = await uret(
        islemler: <Islem>[
          Islem.fatura(
            id: '01',
            tip: IslemTipi.satisFaturasi,
            baslik: 'Şeftali-Ayçiçeği-İĞDE',
            islemTarihi: DateTime(2025, 3, 8),
            kalemler: <IslemKalemi>[
              IslemKalemi.birimFiyattan(
                ad: 'şeftali cılğa',
                miktar: 1200,
                birimFiyat: Kurus.liradan(38, 50),
              ),
            ],
          ),
        ],
      );

      expect(baytlar.length, greaterThan(1000));
    });
  });

  group('Tutarsız ekstre', () {
    test('PDF üretilmez, doğrulama hatası verir', () async {
      final fontlar = await EkstreFontlari.yukle();
      final bozuk = Ekstre(
        isletme: ornekIsletme,
        cari: ornekCari,
        aralik: const EkstreAraligi.tumu(),
        // Referans yazılımın hatası: tablo ile toplamlar tutmuyor.
        dokum: const BakiyeDokumu(
          satirlar: [],
          devir: Kurus.sifir,
          toplamBorc: Kurus(31400000),
          toplamAlacak: Kurus(32603125),
          bakiye: Kurus.sifir,
        ),
        hazirlanmaTarihi: hazirlanma,
      );

      expect(bozuk.tutarliMi, isFalse);
      expect(
        () => EkstreBelgesi.uret(ekstre: bozuk, fontlar: fontlar),
        throwsA(isA<DogrulamaHatasi>()),
      );
    });
  });

  group('Açıklama biçimi', () {
    test('fatura: tip adı, başlık ve durum', () {
      expect(
        ekstreAciklamasi(zeytinHurmaFaturasi),
        'Satış Faturası — Zeytin-Hurma (TESLİM EDİLDİ)',
      );
    });

    test('alış faturası durumsuz basılır', () {
      expect(
        ekstreAciklamasi(sertCekirdekliFaturasi),
        'Alış Faturası — Sert Çekirdekli Meyve Fidanı',
      );
    });

    test('tahsilatta tip adı tekrarlanmaz', () {
      expect(ekstreAciklamasi(tahsilatlar[0]), 'Müşteriden Tahsilat');
    });

    test('iptal edilmiş işlem işaretlenir', () {
      expect(
        ekstreAciklamasi(tahsilatlar[0].kopyala(iptal: true)),
        'Müşteriden Tahsilat (İPTAL EDİLDİ)',
      );
    });
  });

  group('Dosya adı', () {
    test('Türkçe karakterler ASCII\'ye indirgenir', () {
      final ekstre = EkstreOlusturucu.olustur(
        isletme: ornekIsletme,
        cari: ornekCari,
        aralik: const EkstreAraligi.tumu(),
        islemler: referansIslemleri,
        hazirlanmaTarihi: hazirlanma,
      );

      expect(EkstreBelgesi.dosyaAdi(ekstre), 'ekstre-igde-tarim-24-05-2025.pdf');
    });
  });
}

/// PDF baytlarını çözümlenebilir metne çevirir. Sözlük nesneleri sıkıştırılmaz;
/// yapı anahtarları düz metin olarak okunabilir.
String _metin(Uint8List baytlar) => latin1.decode(baytlar, allowInvalid: true);

/// Sayfa ağacındaki `/Count` değeri = sayfa sayısı.
int _sayfaSayisi(Uint8List baytlar) {
  final eslesme = RegExp(r'/Count (\d+)').firstMatch(_metin(baytlar));
  expect(eslesme, isNotNull, reason: 'sayfa ağacı bulunamadı');
  return int.parse(eslesme!.group(1)!);
}

/// Çok sayfalı çıktıyı zorlamak için üretilen işlem listesi.
List<Islem> _cokIslem(int adet) => <Islem>[
  for (var sira = 0; sira < adet; sira++)
    Islem.odeme(
      id: sira.toString().padLeft(3, '0'),
      tip: sira.isEven ? IslemTipi.tahsilat : IslemTipi.odeme,
      baslik: sira.isEven ? 'Müşteriden Tahsilat' : 'Cariye Ödeme',
      islemTarihi: DateTime(2024, 1, 1).add(Duration(days: sira)),
      tutar: Kurus.liradan(1000 + sira),
    ),
];
