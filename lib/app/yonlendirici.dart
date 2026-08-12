import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/firebase/firebase_saglayicilar.dart';
import '../data/isletme/isletme_repository.dart';
import '../domain/isletme/isletme.dart';
import '../features/cari/view/cari_detay_ekrani.dart';
import '../features/cari/view/cari_duzenle_ekrani.dart';
import '../features/cari/view/cari_form_ekrani.dart';
import '../features/cari/view/cari_listesi_ekrani.dart';
import '../features/fidan/view/fidan_duzenle_ekrani.dart';
import '../features/fidan/view/fidan_form_ekrani.dart';
import '../features/fidan/view/fidan_listesi_ekrani.dart';
import '../features/isletme/view/isletme_ekrani.dart';
import '../features/kimlik/view/giris_ekrani.dart';
import '../features/kimlik/view/kayit_ekrani.dart';
import '../features/kurulum/view/kurulum_ekrani.dart';
import '../features/ortak/view/acilis_ekrani.dart';
import 'yollar.dart';

/// Uygulama yönlendiricisi.
///
/// İki kapı var: oturum ve kurulum. Kullanıcı giriş yapmadan hiçbir veri
/// ekranını, işletme profilini doldurmadan da cari ekranlarını göremez.
///
/// Durum değiştiğinde yönlendirici yeniden kurulmaz; yalnızca
/// [GoRouter.refreshListenable] tetiklenir. Böylece giriş/çıkışta gezinme yığını
/// sıfırlanmaz ve ekran titremez.
final yonlendiriciSaglayici = Provider<GoRouter>((ref) {
  final oturumBildirici = ValueNotifier<AsyncValue<User?>>(
    const AsyncValue<User?>.loading(),
  );
  final profilBildirici = ValueNotifier<AsyncValue<Isletme?>>(
    const AsyncValue<Isletme?>.loading(),
  );
  ref.onDispose(oturumBildirici.dispose);
  ref.onDispose(profilBildirici.dispose);

  ref.listen<AsyncValue<User?>>(
    oturumDurumuSaglayici,
    (onceki, yeni) => oturumBildirici.value = yeni,
    fireImmediately: true,
  );
  ref.listen<AsyncValue<Isletme?>>(
    isletmeProfiliSaglayici,
    (onceki, yeni) => profilBildirici.value = yeni,
    fireImmediately: true,
  );

  final degisimler = Listenable.merge([oturumBildirici, profilBildirici]);

  return GoRouter(
    initialLocation: Yollar.acilis,
    refreshListenable: degisimler,
    redirect: (context, durum) {
      final oturum = oturumBildirici.value;
      final konum = durum.matchedLocation;

      // Oturum durumu henüz bilinmiyor: açılış ekranında bekle.
      if (oturum.isLoading) {
        return konum == Yollar.acilis ? null : Yollar.acilis;
      }

      final kimliksizYolda = Yollar.kimliksizYollar.contains(konum);

      if (oturum.value == null) {
        return kimliksizYolda && konum != Yollar.acilis ? null : Yollar.giris;
      }

      // Giriş yapıldı; sıra kurulumda.
      final profil = profilBildirici.value;
      if (profil.isLoading) {
        return konum == Yollar.acilis ? null : Yollar.acilis;
      }

      // Profil okunamadıysa (yetki, ağ) kullanıcıyı kurulumda tutmak yerine
      // uygulamaya alıyoruz: çevrimdışı önbellek boşsa da uygulama açılmalı.
      final kurulumTamam = profil.hasError || profil.value != null;
      if (!kurulumTamam) {
        return konum == Yollar.kurulum ? null : Yollar.kurulum;
      }

      return kimliksizYolda || konum == Yollar.kurulum ? Yollar.ana : null;
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
        path: Yollar.kurulum,
        builder: (context, durum) => const KurulumEkrani(),
      ),
      GoRoute(
        path: Yollar.ana,
        builder: (context, durum) => const CariListesiEkrani(),
      ),
      GoRoute(
        path: Yollar.isletme,
        builder: (context, durum) => const IsletmeEkrani(),
      ),
      // `/cari/yeni`, `/cari/:cariId` kalıbından **önce** tanımlanmalı;
      // go_router yolları sırayla eşleştirir ve aksi hâlde "yeni" bir cari
      // kimliği sanılır.
      GoRoute(
        path: Yollar.cariYeni,
        builder: (context, durum) => const CariFormEkrani(),
      ),
      // Düzenleme yolu iç içe değil, ayrı bir kök yol: `push` iç içe yolda
      // eşleşen tüm sayfaları yığına koyar ve detay ekranı iki kez açılırdı.
      GoRoute(
        path: Yollar.cariDuzenle,
        builder: (context, durum) => CariDuzenleEkrani(
          cariId: durum.pathParameters[Yollar.cariIdParametresi]!,
        ),
      ),
      GoRoute(
        path: Yollar.cariDetay,
        builder: (context, durum) => CariDetayEkrani(
          cariId: durum.pathParameters[Yollar.cariIdParametresi]!,
        ),
      ),
      GoRoute(
        path: Yollar.fidanlar,
        builder: (context, durum) => const FidanListesiEkrani(),
      ),
      // `/fidanlar/yeni`, `/fidanlar/:fidanId` kalıbından **önce** tanımlanmalı;
      // aksi hâlde "yeni" bir fidan kimliği sanılır.
      GoRoute(
        path: Yollar.fidanYeni,
        builder: (context, durum) => const FidanFormEkrani(),
      ),
      GoRoute(
        path: Yollar.fidanDuzenle,
        builder: (context, durum) => FidanDuzenleEkrani(
          fidanId: durum.pathParameters[Yollar.fidanIdParametresi]!,
        ),
      ),
    ],
  );
});
