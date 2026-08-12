import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../core/metin/turkce.dart' as turkce;
import '../../domain/fidan/fidan.dart';
import '../../domain/fidan/fidan_oneri_alani.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';
import 'fidan_kaydi.dart';
import 'fidan_sayfasi.dart';

/// `isletmeler/{isletmeId}/fidanlar` koleksiyonunun tek erişim noktası.
///
/// Firestore tipleri bu sınıfın dışına çıkmaz; sayfalama imleci bile
/// `DocumentSnapshot` yerine bir önceki sayfanın son [Fidan] kaydından üretilir
/// (bkz. KURALLAR.md §1.3).
///
/// Liste her zaman [Fidan.alanAramaAnahtari] sırasına göre gelir. Anahtar
/// `"tur cesit anac"` biçiminde olduğundan bu sıralama aynı türü **yan yana**
/// getirir; ekran ayrıca gruplamak için sorgu atmaz.
class FidanRepository {
  const FidanRepository({
    required FirebaseFirestore firestore,
    required String isletmeId,
  }) : _firestore = firestore,
       _isletmeId = isletmeId;

  /// Öntakı aramasında aralığın üst sınırı. Unicode'un özel kullanım alanındaki
  /// bu karakter, aynı öntakıyla başlayan her metnin ardında sıralanır.
  static const String _aramaUstSiniri = '\uf8ff';

  static const int varsayilanSayfaBoyu = 30;

  /// Öneri üretmek için taranan en fazla kayıt sayısı.
  ///
  /// Firestore `distinct` bilmiyor; ayrı değerler taranan belgelerden
  /// türetiliyor. Sınır olmasa "El" öntakısı katalogdaki tüm elmaları okurdu
  /// (KURALLAR.md §4.3).
  static const int oneriTaramaSiniri = 40;

  /// Kullanıcıya gösterilen en fazla öneri sayısı.
  static const int enCokOneri = 8;

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  CollectionReference<Map<String, dynamic>> get _koleksiyon => _firestore
      .collection(Isletme.koleksiyon)
      .doc(_isletmeId)
      .collection(Fidan.koleksiyon);

  /// Katalogdaki aktif fidanların bir sayfasını döner.
  Future<FidanSayfasi> listele({
    String arama = '',
    FidanKaydi? sonrasindan,
    int sayfaBoyu = varsayilanSayfaBoyu,
  }) async {
    try {
      var sorgu = _sorguKur(turkce.aramaAnahtari(arama));
      if (sonrasindan != null) {
        sorgu = sorgu.startAfter(<Object?>[
          sonrasindan.fidan.aramaAnahtari,
          sonrasindan.fidan.id,
        ]);
      }

      final anlik = await sorgu.limit(sayfaBoyu).get();
      return FidanSayfasi(
        kayitlar: anlik.docs.map(_kayda).toList(growable: false),
        dahaVar: anlik.docs.length == sayfaBoyu,
      );
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Fidan katalogu okunamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  /// Tek bir fidanı canlı izler. Belge silinmiş ya da hiç yoksa `null` yayar.
  Stream<FidanKaydi?> izle(String fidanId) {
    return _koleksiyon
        .doc(fidanId)
        .snapshots()
        .map((anlik) => anlik.exists ? _kayda(anlik) : null)
        .handleError((Object hata, StackTrace yigin) {
          Log.hata('Fidan izlenemedi: $fidanId', hata, yigin);
          throw _veriHatasi(hata);
        }, test: (hata) => hata is FirebaseException);
  }

  /// Yeni fidan ekler ve oluşan belge kimliğini döner.
  ///
  /// Yazma future'ı **beklenmez**; çevrimdışıyken `set` yalnızca sunucu
  /// onayında tamamlanır ve ekran kilitlenirdi (bkz. KURALLAR.md §4.4).
  Future<String> ekle(Fidan fidan) async {
    final belge = _koleksiyon.doc();
    final veri = <String, Object?>{
      ...fidan.duzenlenebilirAlanlar(),
      Fidan.alanAktif: true,
      Fidan.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
      Fidan.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(belge.set(veri), 'Fidan eklenemedi: ${belge.id}');
    return belge.id;
  }

  /// Fidanı günceller. Aktiflik ve oluşturma tarihi olduğu gibi kalır.
  ///
  /// Geçmiş faturalardaki kalem adları **değişmez**: kalem, kaydedildiği andaki
  /// adı ve tutarı kendi içinde taşır (bkz. `IslemKalemi`). Katalogdaki fiyat
  /// düzeltmesi eski faturaları geriye dönük kaydırmaz — KURALLAR.md §3.2.
  Future<void> guncelle(Fidan fidan) async {
    if (fidan.yeniMi) {
      throw const VeriHatasi('Kaydedilmemiş fidan güncellenemez.');
    }
    final veri = <String, Object?>{
      ...fidan.duzenlenebilirAlanlar(),
      Fidan.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(
      _koleksiyon.doc(fidan.id).update(veri),
      'Fidan güncellenemedi: ${fidan.id}',
    );
  }

  /// Fidanı katalogdan kaldırır ya da geri açar.
  ///
  /// Kayıt silinmez: silinen bir fidana bağlı geçmiş fatura kalemlerinin
  /// `fidanId` alanı boşa düşerdi (bkz. KURALLAR.md §4.2).
  Future<void> aktifligiDegistir(String fidanId, {required bool aktif}) async {
    _yazmayiBaslat(
      _koleksiyon.doc(fidanId).update(<String, Object?>{
        Fidan.alanAktif: aktif,
        Fidan.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
      }),
      'Fidan durumu değiştirilemedi: $fidanId',
    );
  }

  /// Katalogda [fidan] ile aynı tür/çeşit/anaç üçlüsüne sahip kayıtları döner.
  ///
  /// Mükerrer kayıt katalogu zamanla çöplüğe çevirir; ekleme ekranı bu listeyi
  /// kullanıcıya gösterir. Yaş ve kök tipi karşılaştırması çağıran tarafta
  /// yapılır ([Fidan.ayniFidanMi]) — "aynı fidanın 1 ve 2 yaşlısı" mükerrer
  /// değil, ayrı iki kayıttır.
  ///
  /// Fidanın kendisi listeye alınmaz; düzenleme ekranı kendi kaydını mükerrer
  /// sanmasın diye.
  Future<List<Fidan>> benzerleriBul(Fidan fidan) async {
    final anahtar = fidan.aramaAnahtari;
    if (anahtar.isEmpty) return const <Fidan>[];

    try {
      final anlik = await _koleksiyon
          .where(Fidan.alanAktif, isEqualTo: true)
          .where(Fidan.alanAramaAnahtari, isEqualTo: anahtar)
          .limit(enCokOneri)
          .get();

      return anlik.docs
          .where((belge) => belge.id != fidan.id)
          .map((belge) => Fidan.fromMap(belge.id, firestoreHaritasi(belge.data())))
          .toList(growable: false);
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Benzer fidanlar aranamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  /// [alan] için daha önce girilmiş değerlerden [onek] ile başlayanları döner.
  ///
  /// "El" yazınca "Elma" önerilir. Değerler kullanıcının yazdığı hâliyle
  /// (`Elma`) döner, normalize hâliyle değil; süzme normalize alan üzerinden
  /// yapıldığı için `ELMA` yazımı da aynı sonucu verir (KURALLAR.md §6.1).
  Future<List<String>> oneriler({
    required FidanOneriAlani alan,
    String onek = '',
    int limit = enCokOneri,
  }) async {
    final anahtarAlani = switch (alan) {
      FidanOneriAlani.tur => Fidan.alanTurAnahtari,
      FidanOneriAlani.anac => Fidan.alanAnacAnahtari,
    };
    final degerAlani = switch (alan) {
      FidanOneriAlani.tur => Fidan.alanTur,
      FidanOneriAlani.anac => Fidan.alanAnac,
    };
    final anahtar = turkce.aramaAnahtari(onek);

    try {
      final anlik = await _koleksiyon
          .where(Fidan.alanAktif, isEqualTo: true)
          .where(anahtarAlani, isGreaterThanOrEqualTo: anahtar)
          .where(anahtarAlani, isLessThan: '$anahtar$_aramaUstSiniri')
          .orderBy(anahtarAlani)
          .limit(oneriTaramaSiniri)
          .get();

      // `Set` ekleme sırasını koruyor; sıralama sorgudan geliyor, bu yüzden
      // sonuç zaten normalize anahtar sırasında.
      final degerler = <String>{};
      for (final belge in anlik.docs) {
        final deger = belge.data()[degerAlani];
        if (deger is String && deger.trim().isNotEmpty) {
          degerler.add(deger.trim());
        }
        if (degerler.length >= limit) break;
      }
      return degerler.toList(growable: false);
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Fidan önerileri okunamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  Query<Map<String, dynamic>> _sorguKur(String aramaAnahtari) {
    Query<Map<String, dynamic>> sorgu = _koleksiyon.where(
      Fidan.alanAktif,
      isEqualTo: true,
    );

    if (aramaAnahtari.isNotEmpty) {
      sorgu = sorgu
          .where(Fidan.alanAramaAnahtari, isGreaterThanOrEqualTo: aramaAnahtari)
          .where(
            Fidan.alanAramaAnahtari,
            isLessThan: '$aramaAnahtari$_aramaUstSiniri',
          );
    }

    // Aynı anahtara sahip iki fidan (yalnızca yaşı farklı kayıtlar) varsa
    // sıralama belirsiz kalır ve sayfa sınırında kayıt tekrarlanır ya da
    // atlanır. Belge kimliği ikinci ölçüt olarak sıralamayı tekilleştirir.
    return sorgu
        .orderBy(Fidan.alanAramaAnahtari)
        .orderBy(FieldPath.documentId);
  }

  FidanKaydi _kayda(DocumentSnapshot<Map<String, dynamic>> anlik) => FidanKaydi(
    fidan: Fidan.fromMap(anlik.id, firestoreHaritasi(anlik.data())),
    beklemede: anlik.metadata.hasPendingWrites,
  );

  /// Beklenmeyen yazmayı başlatır ve hatasını yalnızca loglar.
  ///
  /// Çevrimdışı yazmalar sunucuya ulaşana kadar tamamlanmaz; bu future'ı
  /// beklemek arayüzü kilitler. Sessiz kalmamak için hata günlüğe düşer.
  void _yazmayiBaslat(Future<void> yazma, String hataMesaji) {
    unawaited(
      yazma.catchError((Object hata, StackTrace yigin) {
        Log.hata(hataMesaji, hata, yigin);
      }),
    );
  }

  VeriHatasi _veriHatasi(Object hata) {
    if (hata is FirebaseException && hata.code == 'permission-denied') {
      return const VeriHatasi.yetkisiz();
    }
    return const VeriHatasi.okunamadi();
  }
}

/// Giriş yapmış kullanıcının fidan katalogu.
final fidanRepositorySaglayici = Provider<FidanRepository>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.yetkisiz();

  return FidanRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});
