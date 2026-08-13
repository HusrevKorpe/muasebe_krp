import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/hata/hatalar.dart';
import '../data/isletme/isletme_repository.dart';
import '../data/kimlik/kimlik_repository.dart';
import '../domain/islem/islem_tipi.dart';
import '../domain/isletme/isletme.dart';
import '../features/ayarlar/view/ayarlar_ekrani.dart';
import '../features/cari/view/cari_detay_ekrani.dart';
import '../features/cari/view/cari_duzenle_ekrani.dart';
import '../features/cari/view/cari_form_ekrani.dart';
import '../features/cari/view/cari_listesi_ekrani.dart';
import '../features/ekstre/view/ekstre_ekrani.dart';
import '../features/giris/view/giris_ekrani.dart';
import '../features/islem/view/fatura_form_ekrani.dart';
import '../features/islem/view/islem_detay_ekrani.dart';
import '../features/islem/view/tahsilat_form_ekrani.dart';
import '../features/isletme/view/isletme_ekrani.dart';
import '../features/ortak/view/acilis_ekrani.dart';
import '../features/urun/view/urun_duzenle_ekrani.dart';
import '../features/urun/view/urun_form_ekrani.dart';
import '../features/urun/view/urun_listesi_ekrani.dart';
import 'kabuk.dart';
import 'yollar.dart';

/// Uygulama yönlendiricisi.
///
/// Tek kapı var: giriş. Uygulamayı birkaç kişi kullanıyor ve hepsi aynı
/// defteri görüyor; kimlik Google hesabıyla doğrulanıyor, erişim iznini ise
/// sunucudaki izin listesi veriyor. Buradaki üç durum:
///
/// * Saklanan oturum henüz yüklenmedi → açılış ekranı.
/// * Oturum yok → giriş ekranı.
/// * Oturum var ama hesap izin listesinde değil → yine giriş ekranı; orası
///   durumu anlatıp çıkış düğmesini gösteriyor.
///
/// İşletme profili artık bir kapı değil: doldurulmadan da uygulama açılır.
///
/// Durum değiştiğinde yönlendirici yeniden kurulmaz; yalnızca
/// [GoRouter.refreshListenable] tetiklenir. Böylece gezinme yığını sıfırlanmaz
/// ve ekran titremez.
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
    oturumSaglayici,
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

      // Akıştan henüz ilk yayın gelmedi: saklanan oturum yükleniyor, açılış
      // ekranında bekle. `isLoading` yerine "değer de hata da yok" diye
      // soruluyor; tazelemede `isLoading` elinde değer varken de doğru olur ve
      // kullanıcı açılış ekranına geri sıçrardı.
      if (!oturum.hasValue && !oturum.hasError) {
        return konum == Yollar.acilis ? null : Yollar.acilis;
      }

      // Oturum yok — ya da okunamadı; ikisinde de yapılacak şey aynı.
      if (oturum.value == null) {
        return konum == Yollar.giris ? null : Yollar.giris;
      }

      // Oturum var; sıra erişim izninde. İzin listesi sunucuda olduğu için
      // yoklama profil belgesi üzerinden yapılıyor.
      if (profilBildirici.value.error is YetkiHatasi) {
        return konum == Yollar.giris ? null : Yollar.giris;
      }

      // Profilin yüklenmesi beklenmiyor: yokluğu da geçerli bir durum ve
      // çevrimdışı önbellek boşsa da uygulama açılmalı.
      return konum == Yollar.acilis || konum == Yollar.giris
          ? Yollar.ana
          : null;
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
      // Alt sekmeler. Her dal kendi yığınını korur; kişi sayfası ve giriş
      // formları bilerek kabuğun dışında, kök gezinmede duruyor.
      StatefulShellRoute.indexedStack(
        builder: (context, durum, gezinme) => Kabuk(gezinme: gezinme),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Yollar.ana,
                builder: (context, durum) => const CariListesiEkrani(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Yollar.urunler,
                builder: (context, durum) => const UrunListesiEkrani(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Yollar.ayarlar,
                builder: (context, durum) => const AyarlarEkrani(),
              ),
            ],
          ),
        ],
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
      // İşlem yolları da kök yol olarak tanımlı — bkz. yukarıdaki düzenleme
      // yolu notu. `yeni` yolu, işlem kimliği kalıbından önce gelmeli.
      GoRoute(
        path: Yollar.islemYeni,
        builder: (context, durum) {
          final cariId = durum.pathParameters[Yollar.cariIdParametresi]!;
          final tip =
              IslemTipi.anahtardan(
                durum.pathParameters[Yollar.tipParametresi],
              ) ??
              IslemTipi.satisFaturasi;

          return tip.faturaMi
              ? FaturaFormEkrani(cariId: cariId, tip: tip)
              : TahsilatFormEkrani(cariId: cariId, tip: tip);
        },
      ),
      // Ekstre yolu, `/cari/:cariId/islem/:islemId` kalıbıyla karışmaz ama
      // sıralama tutarlılığı için işlem yollarının yanında duruyor.
      GoRoute(
        path: Yollar.ekstre,
        builder: (context, durum) => EkstreEkrani(
          cariId: durum.pathParameters[Yollar.cariIdParametresi]!,
        ),
      ),
      GoRoute(
        path: Yollar.islemDetay,
        builder: (context, durum) => IslemDetayEkrani(
          cariId: durum.pathParameters[Yollar.cariIdParametresi]!,
          islemId: durum.pathParameters[Yollar.islemIdParametresi]!,
        ),
      ),
      GoRoute(
        path: Yollar.cariDetay,
        builder: (context, durum) => CariDetayEkrani(
          cariId: durum.pathParameters[Yollar.cariIdParametresi]!,
        ),
      ),
      // `/urunler/yeni`, `/urunler/:urunId` kalıbından **önce** tanımlanmalı;
      // aksi hâlde "yeni" bir ürün kimliği sanılır.
      GoRoute(
        path: Yollar.urunYeni,
        builder: (context, durum) => const UrunFormEkrani(),
      ),
      GoRoute(
        path: Yollar.urunDuzenle,
        builder: (context, durum) => UrunDuzenleEkrani(
          urunId: durum.pathParameters[Yollar.urunIdParametresi]!,
        ),
      ),
    ],
  );
});
