import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../core/metin/turkce.dart' as turkce;
import '../../domain/cari/cari.dart';
import '../../domain/cari/cari_siralamasi.dart';
import '../../domain/cari/cari_suzgeci.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';
import '../kimlik/kimlik_repository.dart';
import 'cari_kaydi.dart';
import 'cari_sayfasi.dart';

/// `isletmeler/{isletmeId}/cariler` koleksiyonunun tek erişim noktası.
///
/// Firestore tipleri bu sınıfın dışına çıkmaz: dışarıya `DocumentSnapshot`
/// değil [CariKaydi] verilir, sayfalama da imleç yerine kayıt sınırıyla
/// yapılır — böylece ViewModel Firestore'u hiç tanımaz (bkz. KURALLAR.md §1.3).
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

  /// Açık hesap sekmesinin sayfa boyu — normalden büyük.
  ///
  /// O sekmenin başındaki toplam yalnızca yüklenmiş kayıtları kapsıyor;
  /// kullanıcı "ne kadar alacağım var" sorusunun cevabını görmek için listeyi
  /// sonuna kadar kaydırmak zorunda kalmamalı. Hesabı açık cari sayısı pratikte
  /// bunun altında kalıyor, yani toplam tek sayfada tamamlanıyor.
  static const int acikHesapSayfaBoyu = 100;

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  CollectionReference<Map<String, dynamic>> get _koleksiyon => _firestore
      .collection(Isletme.koleksiyon)
      .doc(_isletmeId)
      .collection(Cari.koleksiyon);

  /// Aktif carilerin ilk [sinir] tanesini **canlı** yayar.
  ///
  /// Akış önce yerel önbellekten yayar, sunucu cevabı gelince ikinci kez yayar.
  /// Sayfalama imleçle değil [sinir] büyütülerek yapılır — gerekçesi
  /// `AkisListesiViewModel`'de.
  ///
  /// [arama] doluysa sıralama zorunlu olarak ada göre yapılır: Firestore'da
  /// aralık süzgeci uygulanan alan, ilk sıralama alanı olmak zorundadır.
  ///
  /// [suzgec] açık hesapsa aynı kural bakiyeyi ilk sıralama alanı yapar ve
  /// [arama] ile [siralama] yok sayılır — bkz. [_etkinSiralama].
  ///
  /// Müşteri sekmesinde grup süzgeci **sunucuda değil elde** uygulanır;
  /// gerekçesi [CariSuzgeci.sunucuGrubu]'nda. Sayfanın [CariSayfasi.dahaVar]
  /// bayrağı ham belge sayısına bakar: elde ayıklanan kayıtlar sonraki sayfanın
  /// var olduğunu gizlememeli.
  Stream<CariSayfasi> listeyiIzle({
    CariSuzgeci suzgec = CariSuzgeci.musteriler,
    CariSiralamasi siralama = CariSiralamasi.ad,
    String arama = '',
    int sinir = varsayilanSayfaBoyu,
  }) {
    // Açık hesap süzgeci bakiyeye, arama ada aralık süzgeci uyguluyor.
    // Firestore ikisini de ilk sıralama alanı olmaya zorlar; aynı sorguda
    // birleşemezler. Açık hesap sekmesinde arama kutusu bu yüzden yok.
    assert(
      !suzgec.acikHesapMi || turkce.aramaAnahtari(arama).isEmpty,
      'Açık hesap süzgeci aramayla birleşmiyor.',
    );

    final anahtar = suzgec.acikHesapMi ? '' : turkce.aramaAnahtari(arama);
    final etkinSiralama = _etkinSiralama(suzgec, siralama, anahtar);

    return _sorguKur(suzgec, etkinSiralama, anahtar)
        .limit(sinir)
        .snapshots()
        .map(
          (anlik) => CariSayfasi(
            kayitlar: anlik.docs
                .map(_kayda)
                .where((kayit) => suzgec.kayitGirerMi(kayit.cari.grup))
                .toList(growable: false),
            dahaVar: anlik.docs.length == sinir,
          ),
        )
        .handleError((Object hata, StackTrace yigin) {
          Log.hata('Cari listesi okunamadı', hata, yigin);
          throw _veriHatasi(hata);
        }, test: (hata) => hata is FirebaseException);
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

  /// Sorgunun gerçekte kullanacağı sıralama.
  ///
  /// Firestore, aralık süzgeci uygulanan alanın ilk sıralama alanı olmasını
  /// şart koşar; çağıranın seçtiği ölçüt bu yüzden her zaman geçerli olmuyor.
  /// Açık hesapta bakiyeye göre sıralamak zaten istenen davranış: en borçlu
  /// başta gelir.
  static CariSiralamasi _etkinSiralama(
    CariSuzgeci suzgec,
    CariSiralamasi siralama,
    String aramaAnahtari,
  ) => switch (suzgec) {
    CariSuzgeci.acikHesap => CariSiralamasi.bakiye,
    CariSuzgeci.musteriler ||
    CariSuzgeci.fidancilar => aramaAnahtari.isEmpty
        ? siralama
        : CariSiralamasi.ad,
  };

  Query<Map<String, dynamic>> _sorguKur(
    CariSuzgeci suzgec,
    CariSiralamasi siralama,
    String aramaAnahtari,
  ) {
    Query<Map<String, dynamic>> sorgu = _koleksiyon.where(
      Cari.alanAktif,
      isEqualTo: true,
    );

    // Hesabı kapanmayanlar: bakiyesi sıfırdan farklı olan herkes. Yön ayrımı
    // yok, iki taraf da açık hesap sayılır.
    if (suzgec.acikHesapMi) {
      sorgu = sorgu.where(Cari.alanBakiyeKurus, isNotEqualTo: 0);
    }

    // Yalnızca fidancı listesi sunucuda süzülüyor; müşteri listesi elde
    // ayıklanıyor (bkz. [CariSuzgeci.sunucuGrubu]).
    final grup = suzgec.sunucuGrubu;
    if (grup != null) {
      sorgu = sorgu.where(Cari.alanGrup, isEqualTo: grup.anahtar);
    }

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
      return const VeriHatasi.erisimReddedildi();
    }
    return const VeriHatasi.okunamadi();
  }
}

/// İşletmenin cari deposu.
///
/// Oturum açılmadan `isletmeKimligiSaglayici` `null` olur ve bu sağlayıcı hata
/// verir; ekranlar zaten yönlendirici tarafından açılış ekranında tutulur.
final cariRepositorySaglayici = Provider<CariRepository>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.oturumYok();

  return CariRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});
