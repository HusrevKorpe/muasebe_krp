import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/islem/islem_repository.dart';
import '../../../data/isletme/isletme_repository.dart';
import '../../../domain/ekstre/ekstre.dart';
import '../../../domain/ekstre/ekstre_olusturucu.dart';
import '../../../domain/isletme/isletme.dart';
import '../../cari/viewmodel/cari_saglayici.dart';
import '../view/pdf/ekstre_belgesi.dart';
import '../view/pdf/ekstre_fontlari.dart';
import 'ekstre_araligi_viewmodel.dart';

/// PDF'e gömülen fontlar.
///
/// Ayrıştırma pahalıdır ve sonuç değişmez; sağlayıcı `autoDispose` **değil**
/// ki her ekstre açılışında yeniden okunmasın.
final ekstreFontlariSaglayici = FutureProvider<EkstreFontlari>(
  (ref) => EkstreFontlari.yukle(),
);

/// Seçili aralığın ekstre verisi.
///
/// Üç kaynağı birleştirir: işletme profili (başlık), cari (İLGİLİ FİRMA) ve
/// carinin işlemleri. İşlemler sayfalanmadan çekilir — açılış bakiyesi
/// aralıktan önceki tüm işlemlerin toplamıdır
/// (bkz. [IslemRepository.ekstreIcinGetir]).
///
/// İşletme profili doldurulmamışsa döküm yine üretilir, yalnızca başlığı sade
/// olur: kullanıcıyı, müşterisine hesap dökümü göndermek için önce kendi
/// künyesini yazmaya zorlamıyoruz.
final ekstreSaglayici = FutureProvider.family<Ekstre, String>((
  ref,
  cariId,
) async {
  final aralik = ref.watch(ekstreAraligiSaglayici(cariId));

  final isletme = await ref.watch(isletmeProfiliSaglayici.future);

  final kayit = await ref.watch(cariSaglayici(cariId).future);
  if (kayit == null) throw const VeriHatasi(Metinler.cariBulunamadi);

  final islemler = await ref
      .watch(islemRepositorySaglayici)
      .ekstreIcinGetir(cariId: cariId, bitis: aralik.bitis);

  return EkstreOlusturucu.olustur(
    isletme: isletme ?? Isletme.bos,
    cari: kayit.cari,
    aralik: aralik,
    islemler: islemler,
    hazirlanmaTarihi: DateTime.now(),
  );
}, isAutoDispose: true);

/// Ekstrenin PDF baytları — önizleme ve paylaşma bunu kullanır.
final ekstrePdfSaglayici = FutureProvider.family<Uint8List, String>((
  ref,
  cariId,
) async {
  final ekstre = await ref.watch(ekstreSaglayici(cariId).future);
  final fontlar = await ref.watch(ekstreFontlariSaglayici.future);

  return EkstreBelgesi.uret(ekstre: ekstre, fontlar: fontlar);
}, isAutoDispose: true);
