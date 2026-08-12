import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/ekstre/ekstre_araligi.dart';

/// Ekstre ekranında seçili tarih aralığı.
///
/// Aralık cari başına tutulur: kullanıcı bir cariye "bu yıl", diğerine "tümü"
/// ekstresi çıkarabilir ve iki ekran arasında gidip gelirken seçim kaybolmaz.
///
/// Varsayılan [EkstreAraligi.tumu]: fidancılıkta hesap yıllara yayılıyor ve
/// kullanıcının beklediği ilk çıktı bütün geçmiş — referans ekstre de öyle.
class EkstreAraligiViewModel extends Notifier<EkstreAraligi> {
  EkstreAraligiViewModel(this.cariId);

  final String cariId;

  @override
  EkstreAraligi build() => const EkstreAraligi.tumu();

  void buAy(DateTime bugun) => state = EkstreAraligi.buAy(bugun);

  void buYil(DateTime bugun) => state = EkstreAraligi.buYil(bugun);

  void tumu() => state = const EkstreAraligi.tumu();

  void ozel({required DateTime baslangic, required DateTime bitis}) =>
      state = EkstreAraligi.ozel(baslangic: baslangic, bitis: bitis);
}

final ekstreAraligiSaglayici =
    NotifierProvider.family<EkstreAraligiViewModel, EkstreAraligi, String>(
      EkstreAraligiViewModel.new,
      isAutoDispose: true,
    );
