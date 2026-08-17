import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/log/log.dart';
import '../../domain/tema/tema_tercihi.dart';

/// Tema tercihinin cihazdaki deposu.
///
/// Firestore'a değil cihaza yazılıyor. Defter ortak (`isletmeler/ortak`), ama
/// tema kişisel: bir telefonda koyu tema seçmek öteki kullanıcının ekranını
/// karartmamalı. Ayrıca uygulama daha ilk karesini çizerken tercihe ihtiyaç
/// duyuyor; ağ üzerinden gelen bir değer o an elde olmaz ve ekran açık temayla
/// açılıp bir kare sonra kararırdı.
class TemaRepository {
  const TemaRepository(this._tercihler);

  static const String _anahtar = 'tema';

  final SharedPreferences _tercihler;

  TemaTercihi oku() => TemaTercihi.koddan(_tercihler.getString(_anahtar));

  /// Yazma future'ı **beklenmiyor**: anahtar dokununca tema anında dönmeli,
  /// diske yazmanın bitmesi beklenmemeli (KURALLAR.md §4.4'ün aynı gerekçesi).
  /// Yazma başarısız olursa tercih bu oturumda geçerli kalır, uygulama yeniden
  /// açılınca eskisine döner — kayıp veri yok, sadece bir ayar.
  void yaz(TemaTercihi tercih) {
    _tercihler.setString(_anahtar, tercih.kod).catchError((
      Object hata,
      StackTrace iz,
    ) {
      Log.hata('Tema tercihi cihaza yazılamadı', hata, iz);
      return false;
    });
  }
}

/// `main()` içinde gerçek örnekle değiştirilir.
///
/// [SharedPreferences] açılışı asenkron; sağlayıcıyı burada kurmak ekranı
/// tercih okunana kadar bekletmek ya da bir kare yanlış temayla çizmek
/// demekti. Onun yerine `main()` depoyu açıp buraya enjekte ediyor.
final temaRepositorySaglayici = Provider<TemaRepository>((ref) {
  throw UnimplementedError(
    'temaRepositorySaglayici main() içinde override edilmeli.',
  );
});
