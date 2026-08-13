import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/kimlik/kimlik_repository.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// Giriş ve çıkış işlemleri.
///
/// Oturumun kendisi buradan yayılmaz — onu `oturumSaglayici` izliyor ve
/// yönlendirici ona bakıyor. Bu ViewModel yalnızca düğmeye basıldığında dönen
/// göstergeyi ve hata mesajını taşır.
class GirisViewModel extends IslemViewModel {
  /// Google hesabı seçtirir. Kullanıcı vazgeçerse hata gösterilmez; durum
  /// sessizce eski hâline döner.
  Future<bool> googleIleGir() => calistir(
    () => ref.read(kimlikRepositorySaglayici).girisYap(),
    etiket: 'Google girişi',
  );

  Future<bool> cikisYap() => calistir(
    () => ref.read(kimlikRepositorySaglayici).cikisYap(),
    etiket: 'Çıkış',
  );
}

final girisViewModelSaglayici = AsyncNotifierProvider<GirisViewModel, void>(
  GirisViewModel.new,
);
