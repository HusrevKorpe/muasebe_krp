import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../core/metin/turkce.dart' as turkce;
import '../../domain/cari/cari.dart';
import '../../domain/cari/cari_siralamasi.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';
import 'cari_kaydi.dart';
import 'cari_sayfasi.dart';

/// `isletmeler/{isletmeId}/cariler` koleksiyonunun tek erişim noktası.
///
/// Firestore tipleri bu sınıfın dışına çıkmaz: sayfalama imleci bile
/// `DocumentSnapshot` yerine bir önceki sayfanın son [Cari] kaydından üretilir,
/// böylece ViewModel Firestore'u hiç tanımaz (bkz. KURALLAR.md §1.3).
class CariRepository {
  const CariRepository({
    required FirebaseFirestore firestore,
    required String isletmeId,
  }) : _firestore = firestore,
       _isletmeId = isletmeId;

  /// Öntakı aramasında aralığın üst sınırı. Unicode'un özel kullanım alanındaki
  /// bu karakter, aynı öntakıyla başlayan her metnin ardında sıralanır.
  static const String _aramaUstSiniri = '\uf8ff';

  static const int varsayilanSayfaBoyu = 25;

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  CollectionReference<Map<String, dynamic>> get _koleksiyon => _firestore
      .collection(Isletme.koleksiyon)
      .doc(_isletmeId)
      .collection(Cari.koleksiyon);

  /// Aktif carilerin bir sayfasını döner.
  ///
  /// [arama] doluysa sıralama zorunlu olarak ada göre yapılır: Firestore'da
  /// aralık süzgeci uygulanan alan, ilk sıralama alanı olmak zorundadır.
  Future<CariSayfasi> listele({
    CariSiralamasi siralama = CariSiralamasi.ad,
    String arama = '',
    CariKaydi? sonrasindan,
    int sayfaBoyu = varsayilanSayfaBoyu,
  }) async {
    final anahtar = turkce.aramaAnahtari(arama);
    final etkinSiralama = anahtar.isEmpty ? siralama : CariSiralamasi.ad;

    try {
      var sorgu = _sorguKur(etkinSiralama, anahtar);
      if (sonrasindan != null) {
        sorgu = sorgu.startAfter(
          _imlecDegerleri(etkinSiralama, sonrasindan.cari),
        );
      }

      final anlik = await sorgu.limit(sayfaBoyu).get();
      return CariSayfasi(
        kayitlar: anlik.docs.map(_kayda).toList(growable: false),
        dahaVar: anlik.docs.length == sayfaBoyu,
      );
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Cari listesi okunamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  /// Tek bir cariyi canlı izler. Belge silinmiş ya da hiç yoksa `null` yayar.
  Stream<CariKaydi?> izle(String cariId) {
    return _koleksiyon
        .doc(cariId)
        .snapshots()
        .map((anlik) => anlik.exists ? _kayda(anlik) : null)
        .handleError((Object hata, StackTrace yigin) {
          Log.hata('Cari izlenemedi: $cariId', hata, yigin);
          throw _veriHatasi(hata);
        }, test: (hata) => hata is FirebaseException);
  }

  /// Yeni cari ekler ve oluşan belge kimliğini döner.
  ///
  /// Yazma future'ı **beklenmez**. Firestore çevrimdışıyken `set` yalnızca
  /// sunucu onayında tamamlanır; beklenirse uçak modunda kayıt ekranı sonsuza
  /// kadar kilitli kalır. Yerel önbelleğe yazma anında gerçekleşir ve kayıt
  /// listede `beklemede` işaretiyle görünür (bkz. KURALLAR.md §4.4).
  Future<String> ekle(Cari cari) async {
    final belge = _koleksiyon.doc();
    final veri = <String, Object?>{
      ...cari.duzenlenebilirAlanlar(),
      // Bakiye Faz 2'de işlem kaydıyla birlikte transaction içinde dolar.
      Cari.alanBakiyeKurus: 0,
      // Alan `null` olarak da olsa yazılır: hiç yazılmazsa cari, son işleme
      // göre sıralayan sorgunun sonucuna hiç girmez.
      Cari.alanSonIslemTarihi: null,
      Cari.alanAktif: true,
      Cari.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
      Cari.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(belge.set(veri), 'Cari eklenemedi: ${belge.id}');
    return belge.id;
  }

  /// Cariyi günceller. Yalnızca kullanıcının düzenlediği alanlara dokunur;
  /// bakiye, aktiflik ve oluşturma tarihi olduğu gibi kalır.
  Future<void> guncelle(Cari cari) async {
    if (cari.yeniMi) {
      throw const VeriHatasi('Kaydedilmemiş cari güncellenemez.');
    }
    final veri = <String, Object?>{
      ...cari.duzenlenebilirAlanlar(),
      Cari.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(
      _koleksiyon.doc(cari.id).update(veri),
      'Cari güncellenemedi: ${cari.id}',
    );
  }

  /// Cariyi pasife alır ya da geri açar.
  ///
  /// Muhasebe kaydı fiziksel olarak silinmez; pasif cari listede görünmez ama
  /// geçmiş işlemleriyle veritabanında durur (bkz. KURALLAR.md §4.2).
  Future<void> aktifligiDegistir(String cariId, {required bool aktif}) async {
    _yazmayiBaslat(
      _koleksiyon.doc(cariId).update(<String, Object?>{
        Cari.alanAktif: aktif,
        Cari.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
      }),
      'Cari durumu değiştirilemedi: $cariId',
    );
  }

  Query<Map<String, dynamic>> _sorguKur(
    CariSiralamasi siralama,
    String aramaAnahtari,
  ) {
    Query<Map<String, dynamic>> sorgu = _koleksiyon.where(
      Cari.alanAktif,
      isEqualTo: true,
    );

    if (aramaAnahtari.isNotEmpty) {
      sorgu = sorgu
          .where(Cari.alanAramaAnahtari, isGreaterThanOrEqualTo: aramaAnahtari)
          .where(
            Cari.alanAramaAnahtari,
            isLessThan: '$aramaAnahtari$_aramaUstSiniri',
          );
    }

    // Ada göre sıralama artan, diğerleri azalan: en borçlu ve en son işlem
    // görmüş cari listenin başında olmalı.
    final azalan = siralama != CariSiralamasi.ad;
    sorgu = switch (siralama) {
      CariSiralamasi.ad => sorgu.orderBy(Cari.alanAramaAnahtari),
      CariSiralamasi.bakiye => sorgu.orderBy(
        Cari.alanBakiyeKurus,
        descending: true,
      ),
      CariSiralamasi.sonIslem => sorgu.orderBy(
        Cari.alanSonIslemTarihi,
        descending: true,
      ),
    };

    // Aynı ada ya da aynı bakiyeye sahip iki cari varsa sıralama belirsiz kalır
    // ve sayfalama sınırında kayıt tekrarlanır veya atlanır. Belge kimliği
    // ikinci ölçüt olarak sıralamayı tekilleştirir.
    return sorgu.orderBy(FieldPath.documentId, descending: azalan);
  }

  /// [_sorguKur] içindeki sıralama alanlarıyla **aynı sırada** imleç değerleri.
  List<Object?> _imlecDegerleri(CariSiralamasi siralama, Cari cari) {
    return switch (siralama) {
      CariSiralamasi.ad => <Object?>[cari.aramaAnahtari, cari.id],
      CariSiralamasi.bakiye => <Object?>[cari.bakiye.deger, cari.id],
      CariSiralamasi.sonIslem => <Object?>[
        cari.sonIslemTarihi == null
            ? null
            : Timestamp.fromDate(cari.sonIslemTarihi!),
        cari.id,
      ],
    };
  }

  CariKaydi _kayda(DocumentSnapshot<Map<String, dynamic>> anlik) => CariKaydi(
    cari: Cari.fromMap(anlik.id, firestoreHaritasi(anlik.data())),
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

/// Giriş yapmış kullanıcının cari deposu.
///
/// Oturum kapandığında `isletmeKimligiSaglayici` `null` olur ve bu sağlayıcı
/// hata verir; ekranlar zaten yönlendirici tarafından giriş ekranına taşınır.
final cariRepositorySaglayici = Provider<CariRepository>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.yetkisiz();

  return CariRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});
