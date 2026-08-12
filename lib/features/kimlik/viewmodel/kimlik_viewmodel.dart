import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/log/log.dart';
import '../../../data/kimlik/kimlik_repository.dart';

/// Giriş ve kayıt ekranlarının durumu.
///
/// `BuildContext` taşımaz — gezinme ve mesaj gösterme View'ın işidir.
/// Bkz. KURALLAR.md §1.3.
class KimlikViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> girisYap({
    required String ePosta,
    required String sifre,
  }) =>
      _calistir(() => ref.read(kimlikRepositorySaglayici).girisYap(
            ePosta: ePosta,
            sifre: sifre,
          ));

  Future<bool> kayitOl({
    required String ePosta,
    required String sifre,
  }) =>
      _calistir(() => ref.read(kimlikRepositorySaglayici).kayitOl(
            ePosta: ePosta,
            sifre: sifre,
          ));

  Future<bool> sifreSifirlamaGonder(String ePosta) => _calistir(
        () => ref.read(kimlikRepositorySaglayici).sifreSifirlamaGonder(ePosta),
      );

  Future<void> cikisYap() =>
      ref.read(kimlikRepositorySaglayici).cikisYap();

  /// İşlemi çalıştırır, durumu günceller ve başarılı olup olmadığını döner.
  /// Hata mesajı `state.error` üzerinden okunur.
  Future<bool> _calistir(Future<void> Function() islem) async {
    state = const AsyncValue<void>.loading();
    try {
      await islem();
      state = const AsyncValue<void>.data(null);
      return true;
    } on UygulamaHatasi catch (hata, yigin) {
      Log.uyari('Kimlik işlemi başarısız: ${hata.mesaj}');
      state = AsyncValue<void>.error(hata, yigin);
      return false;
    } catch (hata, yigin) {
      Log.hata('Kimlik işleminde beklenmeyen hata', hata, yigin);
      state = AsyncValue<void>.error(
        const KimlikHatasi('Beklenmeyen bir hata oluştu.'),
        yigin,
      );
      return false;
    }
  }
}

final kimlikViewModelSaglayici = AsyncNotifierProvider<KimlikViewModel, void>(
  KimlikViewModel.new,
  isAutoDispose: true,
);
