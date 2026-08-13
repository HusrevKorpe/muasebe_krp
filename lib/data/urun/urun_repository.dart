import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../core/metin/turkce.dart' as turkce;
import '../../domain/isletme/isletme.dart';
import '../../domain/urun/urun.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';
import '../kimlik/kimlik_repository.dart';
import 'urun_kaydi.dart';
import 'urun_sayfasi.dart';

/// `isletmeler/{isletmeId}/fidanlar` koleksiyonunun tek erişim noktası.
///
/// Koleksiyon adının neden `fidanlar` kaldığı [Urun.koleksiyon]'da anlatılıyor.
///
/// Firestore tipleri bu sınıfın dışına çıkmaz; sayfalama imleci bile
/// `DocumentSnapshot` yerine bir önceki sayfanın son [Urun] kaydından üretilir
/// (bkz. KURALLAR.md §1.3).
///
/// Liste her zaman [Urun.alanAramaAnahtari] sırasına göre gelir — yani ada
/// göre alfabetik.
class UrunRepository {
  const UrunRepository({
    required FirebaseFirestore firestore,
    required String isletmeId,
  }) : _firestore = firestore,
       _isletmeId = isletmeId;

  /// Öntakı aramasında aralığın üst sınırı. Unicode'un özel kullanım alanındaki
  /// bu karakter, aynı öntakıyla başlayan her metnin ardında sıralanır.
  static const String _aramaUstSiniri = '\uf8ff';

  static const int varsayilanSayfaBoyu = 30;

  /// Mükerrer kontrolünde okunan en fazla kayıt sayısı.
  static const int enCokBenzer = 8;

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  CollectionReference<Map<String, dynamic>> get _koleksiyon => _firestore
      .collection(Isletme.koleksiyon)
      .doc(_isletmeId)
      .collection(Urun.koleksiyon);

  /// Listedeki aktif ürünlerin bir sayfasını döner.
  Future<UrunSayfasi> listele({
    String arama = '',
    UrunKaydi? sonrasindan,
    int sayfaBoyu = varsayilanSayfaBoyu,
  }) async {
    try {
      var sorgu = _sorguKur(turkce.aramaAnahtari(arama));
      if (sonrasindan != null) {
        sorgu = sorgu.startAfter(<Object?>[
          sonrasindan.urun.aramaAnahtari,
          sonrasindan.urun.id,
        ]);
      }

      final anlik = await sorgu.limit(sayfaBoyu).get();
      return UrunSayfasi(
        kayitlar: anlik.docs.map(_kayda).toList(growable: false),
        dahaVar: anlik.docs.length == sayfaBoyu,
      );
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Ürün listesi okunamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  /// Tek bir ürünü canlı izler. Belge silinmiş ya da hiç yoksa `null` yayar.
  Stream<UrunKaydi?> izle(String urunId) {
    return _koleksiyon
        .doc(urunId)
        .snapshots()
        .map((anlik) => anlik.exists ? _kayda(anlik) : null)
        .handleError((Object hata, StackTrace yigin) {
          Log.hata('Ürün izlenemedi: $urunId', hata, yigin);
          throw _veriHatasi(hata);
        }, test: (hata) => hata is FirebaseException);
  }

  /// Yeni ürün ekler ve oluşan belge kimliğini döner.
  ///
  /// Yazma future'ı **beklenmez**; çevrimdışıyken `set` yalnızca sunucu
  /// onayında tamamlanır ve ekran kilitlenirdi (bkz. KURALLAR.md §4.4).
  Future<String> ekle(Urun urun) async {
    final belge = _koleksiyon.doc();
    final veri = <String, Object?>{
      ...urun.duzenlenebilirAlanlar(),
      Urun.alanAktif: true,
      Urun.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
      Urun.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(belge.set(veri), 'Ürün eklenemedi: ${belge.id}');
    return belge.id;
  }

  /// Ürünü günceller. Aktiflik ve oluşturma tarihi olduğu gibi kalır.
  ///
  /// Geçmiş faturalardaki kalem adları **değişmez**: kalem, kaydedildiği andaki
  /// adı ve tutarı kendi içinde taşır (bkz. `IslemKalemi`). Listedeki fiyat
  /// düzeltmesi eski faturaları geriye dönük kaydırmaz — KURALLAR.md §3.2.
  Future<void> guncelle(Urun urun) async {
    if (urun.yeniMi) {
      throw const VeriHatasi('Kaydedilmemiş ürün güncellenemez.');
    }
    final veri = <String, Object?>{
      ...urun.duzenlenebilirAlanlar(),
      Urun.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(
      _koleksiyon.doc(urun.id).update(veri),
      'Ürün güncellenemedi: ${urun.id}',
    );
  }

  /// Ürünü listeden kaldırır ya da geri açar.
  ///
  /// Kayıt silinmez: silinen bir ürüne bağlı geçmiş fatura kalemlerinin
  /// `urunId` alanı boşa düşerdi (bkz. KURALLAR.md §4.2).
  Future<void> aktifligiDegistir(String urunId, {required bool aktif}) async {
    _yazmayiBaslat(
      _koleksiyon.doc(urunId).update(<String, Object?>{
        Urun.alanAktif: aktif,
        Urun.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
      }),
      'Ürün durumu değiştirilemedi: $urunId',
    );
  }

  /// Listede [urun] ile aynı adı taşıyan kayıtları döner.
  ///
  /// Mükerrer kayıt listeyi zamanla çöplüğe çevirir; ekleme ekranı bu listeyi
  /// kullanıcıya gösterir. Ürünün kendisi listeye alınmaz; düzenleme ekranı
  /// kendi kaydını mükerrer sanmasın diye.
  Future<List<Urun>> benzerleriBul(Urun urun) async {
    final anahtar = urun.aramaAnahtari;
    if (anahtar.isEmpty) return const <Urun>[];

    try {
      final anlik = await _koleksiyon
          .where(Urun.alanAktif, isEqualTo: true)
          .where(Urun.alanAramaAnahtari, isEqualTo: anahtar)
          .limit(enCokBenzer)
          .get();

      return anlik.docs
          .where((belge) => belge.id != urun.id)
          .map((belge) => Urun.fromMap(belge.id, firestoreHaritasi(belge.data())))
          .toList(growable: false);
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Benzer ürünler aranamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  Query<Map<String, dynamic>> _sorguKur(String aramaAnahtari) {
    Query<Map<String, dynamic>> sorgu = _koleksiyon.where(
      Urun.alanAktif,
      isEqualTo: true,
    );

    if (aramaAnahtari.isNotEmpty) {
      sorgu = sorgu
          .where(Urun.alanAramaAnahtari, isGreaterThanOrEqualTo: aramaAnahtari)
          .where(
            Urun.alanAramaAnahtari,
            isLessThan: '$aramaAnahtari$_aramaUstSiniri',
          );
    }

    // Aynı adı taşıyan iki kayıt varsa sıralama belirsiz kalır ve sayfa
    // sınırında kayıt tekrarlanır ya da atlanır. Belge kimliği ikinci ölçüt
    // olarak sıralamayı tekilleştirir.
    return sorgu.orderBy(Urun.alanAramaAnahtari).orderBy(FieldPath.documentId);
  }

  UrunKaydi _kayda(DocumentSnapshot<Map<String, dynamic>> anlik) => UrunKaydi(
    urun: Urun.fromMap(anlik.id, firestoreHaritasi(anlik.data())),
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
      return const VeriHatasi.oturumYok();
    }
    return const VeriHatasi.okunamadi();
  }
}

/// Giriş yapmış kullanıcının ürün listesi.
final urunRepositorySaglayici = Provider<UrunRepository>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.oturumYok();

  return UrunRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});
