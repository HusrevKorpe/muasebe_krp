import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/kimlik/kimlik_repository.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// Giriş ve çıkış işlemleri.
///
/// Oturumun kendisi buradan yayılmaz — onu `oturumSaglayici` izliyor ve
/// yönlendirici ona bakıyor. Bu ViewModel yalnızca düğmeye basıldığında dönen
/// göstergeyi ve hata mesajını taşır.
class GirisViewModel extends IslemViewModel {
  Future<bool> girisYap({required String ePosta, required String sifre}) =>
      calistir(
        () => ref
            .read(kimlikRepositorySaglayici)
            .girisYap(ePosta: ePosta, sifre: sifre),
        etiket: 'Giriş',
      );

  Future<bool> cikisYap() => calistir(
    () => ref.read(kimlikRepositorySaglayici).cikisYap(),
    etiket: 'Çıkış',
  );
}

final girisViewModelSaglayici = AsyncNotifierProvider<GirisViewModel, void>(
  GirisViewModel.new,
);
