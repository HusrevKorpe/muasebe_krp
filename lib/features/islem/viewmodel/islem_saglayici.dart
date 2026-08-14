import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/islem/islem_kaydi.dart';
import '../../../data/islem/islem_repository.dart';
import '../../ortak/viewmodel/saglayici_onbellegi.dart';

/// Tek bir işlemi canlı izler.
///
/// Detay ekranı listeden gelen kopyayı değil bu akışı okur: işlem iptal
/// edildiğinde ekran kendiliğinden tazelenir. Belge yoksa `null` yayar.
final islemSaglayici =
    StreamProvider.family<IslemKaydi?, ({String cariId, String islemId})>((
      ref,
      anahtar,
    ) {
      birSureSakla(ref);
      return ref
          .watch(islemRepositorySaglayici)
          .izle(cariId: anahtar.cariId, islemId: anahtar.islemId);
    }, isAutoDispose: true);
