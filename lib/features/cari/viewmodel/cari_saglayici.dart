import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/cari/cari_kaydi.dart';
import '../../../data/cari/cari_repository.dart';
import '../../ortak/viewmodel/saglayici_onbellegi.dart';

/// Tek bir cariyi canlı izler.
///
/// Detay ekranı listeden gelen kopyayı değil bu akışı okur: cari düzenlenip
/// geri dönüldüğünde ekran kendiliğinden tazelenir ve işlem girildiğinde bakiye
/// anında güncellenir. Belge yoksa `null` yayar.
final cariSaglayici = StreamProvider.family<CariKaydi?, String>((ref, cariId) {
  birSureSakla(ref);
  return ref.watch(cariRepositorySaglayici).izle(cariId);
}, isAutoDispose: true);
