import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/kimlik/kimlik_repository.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// Giriş, kayıt ve şifre sıfırlama işlemleri.
class KimlikViewModel extends IslemViewModel {
  Future<bool> girisYap({required String ePosta, required String sifre}) =>
      calistir(
        () => ref
            .read(kimlikRepositorySaglayici)
            .girisYap(ePosta: ePosta, sifre: sifre),
        etiket: 'Giriş',
      );

  Future<bool> kayitOl({required String ePosta, required String sifre}) =>
      calistir(
        () => ref
            .read(kimlikRepositorySaglayici)
            .kayitOl(ePosta: ePosta, sifre: sifre),
        etiket: 'Kayıt',
      );

  Future<bool> sifreSifirlamaGonder(String ePosta) => calistir(
    () => ref.read(kimlikRepositorySaglayici).sifreSifirlamaGonder(ePosta),
    etiket: 'Şifre sıfırlama',
  );

  Future<void> cikisYap() => ref.read(kimlikRepositorySaglayici).cikisYap();
}

final kimlikViewModelSaglayici = AsyncNotifierProvider<KimlikViewModel, void>(
  KimlikViewModel.new,
  isAutoDispose: true,
);
