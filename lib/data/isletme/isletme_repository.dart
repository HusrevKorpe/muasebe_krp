import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';
import '../kimlik/kimlik_repository.dart';

/// `isletmeler/{isletmeId}` belgesinin tek erişim noktası.
///
/// Bu belge ekstre başlığını üretir. Doldurulması zorunlu değil: yoksa ekstre
/// başlığı sade çıkar, uygulamanın başka hiçbir yeri buna bakmaz.
///
/// Belge aynı zamanda erişim yoklamasıdır: defterin en üstündeki tek belge
/// olduğu için, izin listesinde olmayan bir hesabın ilk çarptığı yer burasıdır
/// ve yönlendirici bu hatayı görüp kullanıcıyı giriş ekranına döndürür.
class IsletmeRepository {
  const IsletmeRepository({
    required FirebaseFirestore firestore,
    required String isletmeId,
  }) : _firestore = firestore,
       _isletmeId = isletmeId;

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  DocumentReference<Map<String, dynamic>> get _belge =>
      _firestore.collection(Isletme.koleksiyon).doc(_isletmeId);

  /// İşletme profilini canlı izler. Profil doldurulmadıysa `null` yayar.
  ///
  /// Çevrimdışıyken akış hata vermez, önbellekten okur; yani buradan gelen bir
  /// hata gerçekten sunucudan geliyor demektir.
  Stream<Isletme?> izle() {
    return _belge
        .snapshots()
        .map(
          (anlik) => anlik.exists
              ? Isletme.fromMap(anlik.id, firestoreHaritasi(anlik.data()))
              : null,
        )
        .handleError((Object hata, StackTrace yigin) {
          Log.hata('İşletme profili okunamadı', hata, yigin);
          throw _okumaHatasi(hata as FirebaseException);
        }, test: (hata) => hata is FirebaseException);
  }

  Future<Isletme?> getir() async {
    try {
      final anlik = await _belge.get();
      if (!anlik.exists) return null;
      return Isletme.fromMap(anlik.id, firestoreHaritasi(anlik.data()));
    } on FirebaseException catch (hata, yigin) {
      Log.hata('İşletme profili okunamadı: ${hata.code}', hata, yigin);
      throw _okumaHatasi(hata);
    }
  }

  /// Yetki reddi ayrı tutulur: hesabın izin listesinde olmadığını yalnızca bu
  /// kod söyler ve yönlendirici buna bakarak giriş ekranına döner.
  UygulamaHatasi _okumaHatasi(FirebaseException hata) =>
      hata.code == 'permission-denied'
      ? const YetkiHatasi()
      : const VeriHatasi.okunamadi();

  /// Profili yazar. Belge yoksa oluşturur, varsa yalnızca gönderilen alanları
  /// günceller.
  ///
  /// `CariRepository` ile aynı gerekçeyle yazma future'ı beklenmez: çevrimdışı
  /// yapılan kayıt sunucu onayını beklerse ekran kilitlenir
  /// (bkz. KURALLAR.md §4.4).
  Future<void> kaydet(Isletme isletme) async {
    final veri = <String, Object?>{
      ...isletme.duzenlenebilirAlanlar(),
      Isletme.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
      // Yalnızca ilk yazmada konur; merge sayesinde sonraki kayıtlarda
      // özgün oluşturma tarihi korunur.
      if (isletme.olusturmaTarihi == null)
        Isletme.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
    };

    unawaited(
      _belge
          .set(veri, SetOptions(merge: true))
          .catchError((Object hata, StackTrace yigin) {
            Log.hata('İşletme profili yazılamadı', hata, yigin);
          }),
    );
  }
}

final isletmeRepositorySaglayici = Provider<IsletmeRepository>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.oturumYok();

  return IsletmeRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});

/// İşletme profili. Doldurulmadıysa `null` — bu bir eksiklik değil, geçerli
/// bir durum; ekstre başlığı sade çıkar.
///
/// Yönlendirici bu sağlayıcının **hatasına** bakar: [YetkiHatasi] gelirse
/// hesap izin listesinde değildir ve kullanıcı giriş ekranına döner.
final isletmeProfiliSaglayici = StreamProvider<Isletme?>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) return Stream<Isletme?>.value(null);

  return ref.watch(isletmeRepositorySaglayici).izle();
});

/// Hesabın deftere erişimi reddedildi mi.
///
/// İzin listesi sunucuda duruyor ve istemci onu okuyamıyor; tek yoklama yolu
/// defterin kapısını çalmak. Profil akışı [YetkiHatasi] verirse hesap listede
/// değildir.
final erisimReddedildiSaglayici = Provider<bool>((ref) {
  return ref.watch(isletmeProfiliSaglayici).error is YetkiHatasi;
});
