/// Ekstre testlerinin işletme ve cari verisi.
///
/// Tamamı **uydurmadır** — gerçek müşteri verisi veya IBAN
/// repoya girmez (KURALLAR.md §7). Alanlar bilerek Türkçe karakter yüklü
/// seçildi: font gömme doğrulaması bu metinler üzerinden yapılıyor
/// (`fazlar/faz-4-ekstre.md`, kabul kriteri 4).
library;

import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/isletme/banka_hesabi.dart';
import 'package:fidancari/domain/isletme/isletme.dart';

const Isletme ornekIsletme = Isletme(
  id: 'isletme-1',
  ad: 'Yeşilçam Fidancılık',
  unvan: 'Tar.Taş.Hay.Ltd.Şti',
  adres: 'Çiğdem Mah. Söğütlü Cad.\nNo: 42 Şuhut / Afyonkarahisar',
  telefon: '02725550101',
  bankaHesaplari: <BankaHesabi>[
    BankaHesabi(
      banka: 'Ziraat Bankası - 1398',
      iban: 'TR000000000000000000000001',
      hesapNo: '11111111',
    ),
    BankaHesabi(
      banka: 'Garanti Bankası',
      iban: 'TR000000000000000000000002',
    ),
  ],
);

const Cari ornekCari = Cari(
  id: 'cari-1',
  ad: 'İğde Tarım',
  unvan: 'Ltd. Şti.',
  sehir: 'Isparta',
);
