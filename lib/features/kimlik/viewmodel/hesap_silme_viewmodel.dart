import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/isletme/isletme_verisi_repository.dart';
import '../../../data/kimlik/kimlik_repository.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// Hesabı ve ona bağlı tüm veriyi silme akışı.
///
/// Giriş/kayıt durumundan ayrı bir sağlayıcıda duruyor: silme uzun sürebilir ve
/// bu sırada ekranın izlediği tek durum bu olmalı.
class HesapSilmeViewModel extends IslemViewModel {
  /// Sıra önemli:
  ///
  /// 1. **Yeniden doğrula** — Firebase hassas işlemde yakın giriş ister; ayrıca
  ///    bu adım sunucuya gittiği için çevrimdışıyken akış daha ilk adımda,
  ///    hiçbir şey silinmeden durur.
  /// 2. **Veriyi sil** — hesap gidince `isletmeler/{uid}` altına erişim de
  ///    gider; veri önce temizlenmezse arkada erişilemez kayıt kalır.
  /// 3. **Hesabı sil.**
  ///
  /// İkinci adım başarılı olup üçüncüsü düşerse veri gitmiş, hesap durmuş olur.
  /// Kullanıcı tekrar denediğinde silinecek veri kalmadığı için akış hesabı
  /// silmeye kadar ilerler.
  Future<bool> sil(String sifre) => calistir(() async {
    await ref.read(kimlikRepositorySaglayici).yenidenDogrula(sifre);
    await ref.read(isletmeVerisiRepositorySaglayici).tumVeriyiSil();
    await ref.read(kimlikRepositorySaglayici).hesabiSil();
  }, etiket: 'Hesap silme');
}

final hesapSilmeViewModelSaglayici =
    AsyncNotifierProvider<HesapSilmeViewModel, void>(
      HesapSilmeViewModel.new,
      isAutoDispose: true,
    );
