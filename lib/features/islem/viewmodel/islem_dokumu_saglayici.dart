import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/para/kurus.dart';
import '../../../domain/islem/bakiye_dokumu.dart';
import '../../../domain/islem/bakiye_hesaplayici.dart';
import '../../cari/viewmodel/cari_saglayici.dart';
import 'islem_listesi_viewmodel.dart';

/// Ekranda gösterilen işlem satırları ve her satırdaki yürüyen bakiye.
///
/// İki kaynağı birleştirir: yüklenmiş işlem sayfaları ve carinin
/// önbelleklenmiş bakiyesi. Bakiye, listenin **en üstteki** satırının değeridir;
/// aşağı inildikçe her işlemin etkisi geri alınarak o satırın bakiyesi bulunur
/// (bkz. [BakiyeHesaplayici.geriye]).
///
/// Böylece bir sayfa işlem göstermek için carinin tüm geçmişini çekmek gerekmez
/// (KURALLAR.md §4.3). Karşılığında bakiye önbelleği bozuksa **bütün kolon**
/// kayar; onarımı `IslemRepository.bakiyeYenidenHesapla` yapar.
final islemDokumuSaglayici = Provider.family<BakiyeDokumu, String>((
  ref,
  cariId,
) {
  final liste = ref.watch(islemListesiViewModelSaglayici(cariId)).value;
  if (liste == null || liste.bosMu) return BakiyeDokumu.bos;

  final bakiye =
      ref.watch(cariSaglayici(cariId)).value?.cari.bakiye ?? Kurus.sifir;

  return BakiyeHesaplayici.geriye(
    islemler: liste.kayitlar
        .map((kayit) => kayit.islem)
        .toList(growable: false),
    sonBakiye: bakiye,
  );
}, isAutoDispose: true);
