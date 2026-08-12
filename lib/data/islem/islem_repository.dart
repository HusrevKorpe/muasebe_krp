import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../core/para/kurus.dart';
import '../../domain/cari/cari.dart';
import '../../domain/islem/bakiye_hesaplayici.dart';
import '../../domain/islem/islem.dart';
import '../../domain/islem/islem_durumu.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';
import 'islem_kaydi.dart';
import 'islem_kimligi.dart';
import 'islem_sayfasi.dart';

/// `isletmeler/{isletmeId}/cariler/{cariId}/islemler` koleksiyonunun tek
/// erişim noktası.
///
/// ## Bakiye neden `runTransaction` ile güncellenmiyor
///
/// Cari kaydındaki önbelleklenmiş bakiye, işlem kaydıyla **aynı atomik yazmada**
/// güncellenmek zorunda. Bunun Firestore'daki iki yolu var:
///
/// 1. `runTransaction` — belgeyi okur, yeni bakiyeyi hesaplar, yazar.
///    **Çevrimdışı çalışmaz:** transaction sunucu bağlantısı ister, kuyruğa
///    alınmaz ve bağlantı yoksa hata verir. Kullanıcı serada internetsizken
///    fatura giremezdi (Faz 2 kabul kriteri 7, KURALLAR.md §4.4).
/// 2. `WriteBatch` + `FieldValue.increment` — bu dosyanın seçtiği yol.
///    Batch, normal yazma gibi çevrimdışı kuyruğa alınır. `increment` ise
///    sunucuda atomik uygulanır: iki cihaz aynı anda işlem girse de artışlar
///    üst üste biner, biri diğerini ezmez (kabul kriteri 8).
///
/// Yani okuma-değiştirme-yazma yerine "ne kadar değişti" yazılır. Bakiye
/// mutlak değerle yalnızca [bakiyeYenidenHesapla] içinde yazılır; o da bir
/// onarım işlemidir ve zaten sunucuya bağlı çalışır.
class IslemRepository {
  const IslemRepository({
    required FirebaseFirestore firestore,
    required String isletmeId,
  }) : _firestore = firestore,
       _isletmeId = isletmeId;

  static const int varsayilanSayfaBoyu = 25;

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  DocumentReference<Map<String, dynamic>> _cariBelgesi(String cariId) =>
      _firestore
          .collection(Isletme.koleksiyon)
          .doc(_isletmeId)
          .collection(Cari.koleksiyon)
          .doc(cariId);

  CollectionReference<Map<String, dynamic>> _koleksiyon(String cariId) =>
      _cariBelgesi(cariId).collection(Islem.koleksiyon);

  /// Carinin işlemlerini en yeniden en eskiye, sayfa sayfa döner.
  ///
  /// [baslangic] ve [bitis] verilirse yalnızca o tarih aralığındaki işlemler
  /// gelir — Faz 4'teki ekstre bu süzgeci kullanacak.
  Future<IslemSayfasi> listele({
    required String cariId,
    DateTime? baslangic,
    DateTime? bitis,
    IslemKaydi? sonrasindan,
    int sayfaBoyu = varsayilanSayfaBoyu,
  }) async {
    try {
      var sorgu = _sorguKur(cariId, baslangic: baslangic, bitis: bitis);
      if (sonrasindan != null) {
        sorgu = sorgu.startAfter(<Object?>[
          Timestamp.fromDate(sonrasindan.islem.islemTarihi),
          sonrasindan.islem.id,
        ]);
      }

      final anlik = await sorgu.limit(sayfaBoyu).get();
      return IslemSayfasi(
        kayitlar: anlik.docs.map(_kayda).toList(growable: false),
        dahaVar: anlik.docs.length == sayfaBoyu,
      );
    } on FirebaseException catch (hata, yigin) {
      Log.hata('İşlem listesi okunamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  /// Tek bir işlemi canlı izler. Belge yoksa `null` yayar.
  Stream<IslemKaydi?> izle({required String cariId, required String islemId}) {
    return _koleksiyon(cariId)
        .doc(islemId)
        .snapshots()
        .map((anlik) => anlik.exists ? _kayda(anlik) : null)
        .handleError((Object hata, StackTrace yigin) {
          Log.hata('İşlem izlenemedi: $islemId', hata, yigin);
          throw _veriHatasi(hata);
        }, test: (hata) => hata is FirebaseException);
  }

  /// İşlemi kaydeder ve cari bakiyesini aynı batch içinde günceller.
  ///
  /// Yazma future'ı **beklenmez**; çevrimdışıyken sunucu onayı hiç gelmez ve
  /// ekran kilitlenirdi. Kayıt yerel önbellekte anında görünür ve listede
  /// "Kaydedilmedi" işaretiyle durur (bkz. KURALLAR.md §4.4).
  Future<String> ekle({required String cariId, required Islem islem}) async {
    final belge = _koleksiyon(cariId).doc(yeniIslemKimligi());

    final toplu = _firestore.batch();
    toplu.set(belge, <String, Object?>{
      ...islem.yazilabilirAlanlar(),
      Islem.alanIptal: false,
      Islem.alanIptalNedeni: null,
      Islem.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
    });
    toplu.update(
      _cariBelgesi(cariId),
      await _cariGuncellemesi(
        cariId: cariId,
        bakiyeFarki: islem.bakiyeEtkisi,
        islemTarihi: islem.islemTarihi,
      ),
    );

    _yazmayiBaslat(toplu.commit(), 'İşlem eklenemedi: ${belge.id}');
    return belge.id;
  }

  /// İşlemi iptal işaretler ve bakiyeye katkısını geri alır.
  ///
  /// Kayıt **silinmez**: silinen bir tahsilat, sonrasındaki tüm yürüyen
  /// bakiyeleri kaydırır ve geri dönüşü olmaz (bkz. KURALLAR.md §4.2).
  /// Zaten iptalli bir kayıt için hiçbir şey yapılmaz — ikinci bir iptal
  /// bakiyeyi ikinci kez geri alırdı.
  Future<void> iptalEt({
    required String cariId,
    required Islem islem,
    String? neden,
  }) async {
    if (islem.yeniMi) {
      throw const VeriHatasi('Kaydedilmemiş işlem iptal edilemez.');
    }
    if (islem.iptalMi) return;

    final toplu = _firestore.batch();
    toplu.update(_koleksiyon(cariId).doc(islem.id), <String, Object?>{
      Islem.alanIptal: true,
      Islem.alanIptalNedeni: neden,
      Islem.alanDurum: IslemDurumu.iptal.anahtar,
    });
    toplu.update(_cariBelgesi(cariId), <String, Object?>{
      Cari.alanBakiyeKurus: FieldValue.increment(-islem.bakiyeEtkisi.deger),
      Cari.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    });

    _yazmayiBaslat(toplu.commit(), 'İşlem iptal edilemedi: ${islem.id}');
  }

  /// Bakiyeyi carinin **tüm** işlemlerinden baştan hesaplar ve yazar.
  ///
  /// Hem tutarsızlık onarımıdır hem de testin doğruluk ölçütü: sonucu
  /// önbelleklenmiş bakiyeyle aynı çıkmalıdır (Faz 2 kabul kriteri 6).
  ///
  /// Diğer yazmaların aksine bu çağrı sunucuya bağlıdır ve beklenir: onarım,
  /// yerel önbellekteki eksik veriyle yapılamaz.
  Future<Kurus> bakiyeYenidenHesapla(String cariId) async {
    try {
      final anlik = await _koleksiyon(
        cariId,
      ).get(const GetOptions(source: Source.server));

      final islemler = anlik.docs
          .map((belge) => Islem.fromMap(belge.id, firestoreHaritasi(belge.data())))
          .toList(growable: false);
      final bakiye = BakiyeHesaplayici.bakiye(islemler);

      await _cariBelgesi(cariId).update(<String, Object?>{
        Cari.alanBakiyeKurus: bakiye.deger,
        Cari.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
      });

      Log.bilgi(
        'Bakiye yeniden hesaplandı: $cariId → ${bakiye.deger} '
        '(${islemler.length} işlem)',
      );
      return bakiye;
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Bakiye yeniden hesaplanamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  Query<Map<String, dynamic>> _sorguKur(
    String cariId, {
    DateTime? baslangic,
    DateTime? bitis,
  }) {
    Query<Map<String, dynamic>> sorgu = _koleksiyon(cariId);

    if (baslangic != null) {
      sorgu = sorgu.where(
        Islem.alanIslemTarihi,
        isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic),
      );
    }
    if (bitis != null) {
      sorgu = sorgu.where(
        Islem.alanIslemTarihi,
        isLessThanOrEqualTo: Timestamp.fromDate(bitis),
      );
    }

    // Sıralama `domain/islem/islem_siralamasi.dart` ile birebir aynı olmalı:
    // yürüyen bakiye sıraya bağlıdır, sorgu ile ekran ayrışırsa kolon kayar.
    // İptal edilmiş kayıtlar da gelir — listede üstü çizili görünürler.
    return sorgu
        .orderBy(Islem.alanIslemTarihi, descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  /// Cari belgesinde güncellenecek alanlar.
  ///
  /// Bakiye farkı [FieldValue.increment] ile yazılır; sınıf başındaki nota bakın.
  Future<Map<String, Object?>> _cariGuncellemesi({
    required String cariId,
    required Kurus bakiyeFarki,
    required DateTime islemTarihi,
  }) async {
    final guncelleme = <String, Object?>{
      Cari.alanBakiyeKurus: FieldValue.increment(bakiyeFarki.deger),
      Cari.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    if (await _sonIslemTarihiGeriMi(cariId, islemTarihi)) {
      guncelleme[Cari.alanSonIslemTarihi] = Timestamp.fromDate(islemTarihi);
    }
    return guncelleme;
  }

  /// Cari kaydındaki son işlem tarihi, yeni işlemden eski mi?
  ///
  /// Bu alan yalnızca cari listesini sıralamak için kullanılır; bakiye gibi
  /// kuruşu kuruşuna doğru olması gerekmez. Bu yüzden bakiyenin aksine atomik
  /// değil, önbellekten okunup karşılaştırılarak yazılır — geriye tarihli bir
  /// işlem girildiğinde alan geri kaymasın diye. Önbellekte kayıt yoksa
  /// (uygulama yeni açıldı, cari hiç okunmadı) tarih yazılır: sıralamanın
  /// tazelenmesi, hiç yazılmamasından iyidir.
  Future<bool> _sonIslemTarihiGeriMi(String cariId, DateTime yeni) async {
    try {
      final anlik = await _cariBelgesi(
        cariId,
      ).get(const GetOptions(source: Source.cache));
      final mevcut = anlik.data()?[Cari.alanSonIslemTarihi];
      if (mevcut is Timestamp) return !mevcut.toDate().isAfter(yeni);
      return true;
    } on FirebaseException {
      return true;
    }
  }

  IslemKaydi _kayda(DocumentSnapshot<Map<String, dynamic>> anlik) => IslemKaydi(
    islem: Islem.fromMap(anlik.id, firestoreHaritasi(anlik.data())),
    beklemede: anlik.metadata.hasPendingWrites,
  );

  /// Beklenmeyen yazmayı başlatır ve hatasını yalnızca loglar.
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

/// Giriş yapmış kullanıcının işlem deposu.
final islemRepositorySaglayici = Provider<IslemRepository>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.yetkisiz();

  return IslemRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});
