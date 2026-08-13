import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/urun/urun_kaydi.dart';
import '../../../data/urun/urun_repository.dart';

/// Tek bir ürünü canlı izler.
///
/// Düzenleme ekranı listeden gelen kopyayı değil bu akışı okur: kayıt
/// güncellenip geri dönüldüğünde ekran kendiliğinden tazelenir. Belge yoksa
/// `null` yayar.
final urunSaglayici = StreamProvider.family<UrunKaydi?, String>((ref, urunId) {
  return ref.watch(urunRepositorySaglayici).izle(urunId);
}, isAutoDispose: true);
