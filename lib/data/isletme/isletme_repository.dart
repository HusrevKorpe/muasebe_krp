import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';

/// `isletmeler/{isletmeId}` belgesinin tek erişim noktası.
///
/// Bu belge ekstre başlığını üretir ve kurulumda bir kez doldurulur; varlığı
/// aynı zamanda "kurulum tamamlandı mı" sorusunun cevabıdır.
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

  /// İşletme profilini canlı izler. Kurulum yapılmadıysa `null` yayar.
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
          throw const VeriHatasi.okunamadi();
        }, test: (hata) => hata is FirebaseException);
  }

  Future<Isletme?> getir() async {
    try {
      final anlik = await _belge.get();
      if (!anlik.exists) return null;
      return Isletme.fromMap(anlik.id, firestoreHaritasi(anlik.data()));
    } on FirebaseException catch (hata, yigin) {
      Log.hata('İşletme profili okunamadı: ${hata.code}', hata, yigin);
      throw const VeriHatasi.okunamadi();
    }
  }

  /// Profili yazar. Belge yoksa oluşturur, varsa yalnızca gönderilen alanları
  /// günceller.
  ///
  /// `CariRepository` ile aynı gerekçeyle yazma future'ı beklenmez: çevrimdışı
  /// yapılan kurulum sunucu onayını beklerse ekran kilitlenir
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
  if (isletmeId == null) throw const VeriHatasi.yetkisiz();

  return IsletmeRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});

/// Giriş yapmış kullanıcının işletme profili.
///
/// Yönlendirici bu sağlayıcıya bakarak kurulum ekranına yönlendirir: değer
/// `null` ise profil henüz oluşturulmamıştır.
final isletmeProfiliSaglayici = StreamProvider<Isletme?>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) return Stream<Isletme?>.value(null);

  return ref.watch(isletmeRepositorySaglayici).izle();
});
