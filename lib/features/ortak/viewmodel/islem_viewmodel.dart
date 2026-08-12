import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/log/log.dart';
import '../../../core/metin/metinler.dart';

/// Tek seferlik işlemleri (giriş yap, kaydet, pasife al) yürüten ViewModel'ler
/// için ortak taban.
///
/// `BuildContext` taşımaz: gezinme ve mesaj gösterme View'ın işidir. Hata
/// mesajı `state.error` üzerinden okunur (bkz. KURALLAR.md §1.3).
abstract class IslemViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// [islem]'i yürütür, durumu günceller ve başarılı olup olmadığını döner.
  ///
  /// [etiket] yalnızca günlüğe yazılır; kullanıcıya gösterilen metin her zaman
  /// hatanın kendi Türkçe mesajıdır.
  Future<bool> calistir(
    Future<void> Function() islem, {
    required String etiket,
  }) async {
    state = const AsyncValue<void>.loading();
    try {
      await islem();
      state = const AsyncValue<void>.data(null);
      return true;
    } on UygulamaHatasi catch (hata, yigin) {
      Log.uyari('$etiket başarısız: ${hata.mesaj}');
      state = AsyncValue<void>.error(hata, yigin);
      return false;
    } catch (hata, yigin) {
      Log.hata('$etiket sırasında beklenmeyen hata', hata, yigin);
      state = AsyncValue<void>.error(
        const VeriHatasi(Metinler.beklenmeyenHata),
        yigin,
      );
      return false;
    }
  }
}
