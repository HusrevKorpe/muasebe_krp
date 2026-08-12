import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/firebase/firebase_saglayicilar.dart';
import '../features/ana/view/ana_ekran.dart';
import '../features/kimlik/view/giris_ekrani.dart';
import '../features/kimlik/view/kayit_ekrani.dart';
import '../features/ortak/view/acilis_ekrani.dart';
import 'yollar.dart';

/// Uygulama yönlendiricisi.
///
/// Oturum durumu değiştiğinde yönlendirici yeniden kurulmaz; yalnızca
/// [refreshListenable] tetiklenir. Böylece giriş/çıkışta gezinme yığını
/// sıfırlanmaz ve ekran titremez.
final yonlendiriciSaglayici = Provider<GoRouter>((ref) {
  final oturumBildirici = ValueNotifier<AsyncValue<User?>>(
    const AsyncValue<User?>.loading(),
  );
  ref.onDispose(oturumBildirici.dispose);
  ref.listen<AsyncValue<User?>>(
    oturumDurumuSaglayici,
    (onceki, yeni) => oturumBildirici.value = yeni,
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: Yollar.acilis,
    refreshListenable: oturumBildirici,
    redirect: (context, durum) {
      final oturum = oturumBildirici.value;

      // Oturum durumu henüz bilinmiyor: açılış ekranında bekle.
      if (oturum.isLoading) {
        return durum.matchedLocation == Yollar.acilis ? null : Yollar.acilis;
      }

      final girisYapildi = oturum.value != null;
      final kimliksizYolda = Yollar.kimliksizYollar.contains(
        durum.matchedLocation,
      );

      if (!girisYapildi) {
        return kimliksizYolda && durum.matchedLocation != Yollar.acilis
            ? null
            : Yollar.giris;
      }
      return kimliksizYolda ? Yollar.ana : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Yollar.acilis,
        builder: (context, durum) => const AcilisEkrani(),
      ),
      GoRoute(
        path: Yollar.giris,
        builder: (context, durum) => const GirisEkrani(),
      ),
      GoRoute(
        path: Yollar.kayit,
        builder: (context, durum) => const KayitEkrani(),
      ),
      GoRoute(
        path: Yollar.ana,
        builder: (context, durum) => const AnaEkran(),
      ),
    ],
  );
});
