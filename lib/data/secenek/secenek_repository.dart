import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../core/metin/turkce.dart' as turkce;
import '../../domain/isletme/isletme.dart';
import '../../domain/secenek/secenek.dart';
import '../../domain/secenek/secenek_tipi.dart';
import '../firebase/firebase_saglayicilar.dart';
import '../firebase/firestore_donusum.dart';
import '../kimlik/kimlik_repository.dart';
import 'secenek_kaydi.dart';
import 'secenek_sayfasi.dart';

/// `isletmeler/{isletmeId}/{turler|cesitler|anaclar}` koleksiyonlarının tek
/// erişim noktası.
///
/// Üç liste tek sınıftan yönetiliyor: şemaları birebir aynı, tek fark
/// koleksiyon adı ([SecenekTipi.koleksiyon]). Üç ayrı repository yazmak aynı
/// otuz satırı üç kez kopyalamak olurdu.
///
/// Firestore tipleri bu sınıfın dışına çıkmaz: dışarıya `DocumentSnapshot`
/// değil [SecenekKaydi] verilir, sayfalama da imleç yerine kayıt sınırıyla
/// yapılır (bkz. KURALLAR.md §1.3).
///
/// Liste her zaman [Secenek.alanAramaAnahtari] sırasına göre — yani ada göre
/// alfabetik — gelir.
class SecenekRepository {
  const SecenekRepository({
    required FirebaseFirestore firestore,
    required String isletmeId,
  }) : _firestore = firestore,
       _isletmeId = isletmeId;

  /// Öntakı aramasında aralığın üst sınırı. Unicode'un özel kullanım alanındaki
  /// bu karakter, aynı öntakıyla başlayan her metnin ardında sıralanır.
  static const String _aramaUstSiniri = '\uf8ff';

  /// Sayfa boyu ürün listesindekinden büyük: bu listelerin satırı tek kelime,
  /// ekrana çok daha fazlası sığıyor ve kullanıcı seçim yaparken kaydırmak
  /// yerine hepsini bir arada görmeli.
  static const int varsayilanSayfaBoyu = 60;

  /// Mükerrer kontrolünde okunan en fazla kayıt sayısı.
  static const int enCokBenzer = 4;

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  CollectionReference<Map<String, dynamic>> _koleksiyon(SecenekTipi tip) =>
      _firestore
          .collection(Isletme.koleksiyon)
          .doc(_isletmeId)
          .collection(tip.koleksiyon);

  /// [tip] listesinin ilk [sinir] satırını **canlı** yayar.
  ///
  /// Akış önce yerel önbellekten yayar, sunucu cevabı gelince ikinci kez yayar
  /// (bkz. `AkisListesiViewModel`).
  Stream<SecenekSayfasi> listeyiIzle(
    SecenekTipi tip, {
    String arama = '',
    int sinir = varsayilanSayfaBoyu,
  }) {
    return _sorguKur(tip, turkce.aramaAnahtari(arama))
        .limit(sinir)
        .snapshots()
        .map(
          (anlik) => SecenekSayfasi(
            kayitlar: anlik.docs
                .map((belge) => _kayda(tip, belge))
                .toList(growable: false),
            dahaVar: anlik.docs.length == sinir,
          ),
        )
        .handleError((Object hata, StackTrace yigin) {
          Log.hata('${tip.koleksiyon} listesi okunamadı', hata, yigin);
          throw _veriHatasi(hata);
        }, test: (hata) => hata is FirebaseException);
  }

  /// Yeni satır ekler ve oluşan belge kimliğini döner.
  ///
  /// Yazma future'ı **beklenmez**; çevrimdışıyken `set` yalnızca sunucu
  /// onayında tamamlanır ve ekran kilitlenirdi (bkz. KURALLAR.md §4.4).
  Future<String> ekle(Secenek secenek) async {
    final belge = _koleksiyon(secenek.tip).doc();
    final veri = <String, Object?>{
      ...secenek.duzenlenebilirAlanlar(),
      Secenek.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
      Secenek.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(belge.set(veri), 'Liste satırı eklenemedi: ${belge.id}');
    return belge.id;
  }

  /// Satırın adını düzeltir.
  ///
  /// Geçmiş faturalar **etkilenmez**: kalem, kaydedildiği andaki adı kendi
  /// içinde taşır (bkz. `IslemKalemi`). Yazım hatasını düzeltmek yalnızca
  /// bundan sonraki seçimleri değiştirir.
  Future<void> guncelle(Secenek secenek) async {
    if (secenek.yeniMi) {
      throw const VeriHatasi('Kaydedilmemiş liste satırı güncellenemez.');
    }
    final veri = <String, Object?>{
      ...secenek.duzenlenebilirAlanlar(),
      Secenek.alanGuncellemeTarihi: FieldValue.serverTimestamp(),
    };

    _yazmayiBaslat(
      _koleksiyon(secenek.tip).doc(secenek.id).update(veri),
      'Liste satırı güncellenemedi: ${secenek.id}',
    );
  }

  /// Satırı **gerçekten siler**.
  ///
  /// Cari, işlem ve üründe silme yok, pasife alma var: onlara kimlikle bağlı
  /// geçmiş kayıtlar bulunuyor ve silinen belge o bağı boşa düşürürdü
  /// (KURALLAR.md §4.2). Burada öyle bir bağ yok — fatura kalemi bu satırın
  /// kimliğini değil metnini kopyalıyor (bkz. [Secenek]). Kayıt bir muhasebe
  /// kaydı değil, bir yazım kolaylığı; bakiyeye dokunmuyor.
  ///
  /// Karşılığında pasif kayıtları taşımıyoruz: `aktif` alanı olsaydı liste
  /// sorgusu `aktif == true` süzgecini ada göre sıralamayla birleştirir ve
  /// bileşik index isterdi ([SecenekTipi.koleksiyon]). Yanlış yazılmış bir
  /// anacı kullanıcı listeden temizleyebilmeli, ömür boyu taşımak zorunda
  /// kalmamalı.
  Future<void> sil(Secenek secenek) async {
    if (secenek.yeniMi) return;

    _yazmayiBaslat(
      _koleksiyon(secenek.tip).doc(secenek.id).delete(),
      'Liste satırı silinemedi: ${secenek.id}',
    );
  }

  /// Listede [secenek] ile aynı adı taşıyan satırları döner.
  ///
  /// Sorgu **yalnızca yerel önbellekte** koşar: kaydetme düğmesi ağa
  /// bağlanmamalı (bkz. `UrunRepository.benzerleriBul`). Satırın kendisi
  /// listeye alınmaz; düzenleme ekranı kendi kaydını mükerrer sanmasın diye.
  Future<List<Secenek>> benzerleriBul(Secenek secenek) async {
    final anahtar = secenek.aramaAnahtari;
    if (anahtar.isEmpty) return const <Secenek>[];

    try {
      final anlik = await _koleksiyon(secenek.tip)
          .where(Secenek.alanAramaAnahtari, isEqualTo: anahtar)
          .limit(enCokBenzer)
          .get(const GetOptions(source: Source.cache));

      return anlik.docs
          .where((belge) => belge.id != secenek.id)
          .map(
            (belge) => Secenek.fromMap(
              belge.id,
              secenek.tip,
              firestoreHaritasi(belge.data()),
            ),
          )
          .toList(growable: false);
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Benzer liste satırları aranamadı: ${hata.code}', hata, yigin);
      throw _veriHatasi(hata);
    }
  }

  Query<Map<String, dynamic>> _sorguKur(SecenekTipi tip, String aramaAnahtari) {
    Query<Map<String, dynamic>> sorgu = _koleksiyon(tip);

    if (aramaAnahtari.isNotEmpty) {
      sorgu = sorgu
          .where(
            Secenek.alanAramaAnahtari,
            isGreaterThanOrEqualTo: aramaAnahtari,
          )
          .where(
            Secenek.alanAramaAnahtari,
            isLessThan: '$aramaAnahtari$_aramaUstSiniri',
          );
    }

    // Aynı adı taşıyan iki kayıt varsa sıralama belirsiz kalır ve sayfa
    // sınırında kayıt tekrarlanır ya da atlanır. Belge kimliği ikinci ölçüt
    // olarak sıralamayı tekilleştirir (bkz. `UrunRepository._sorguKur`).
    return sorgu
        .orderBy(Secenek.alanAramaAnahtari)
        .orderBy(FieldPath.documentId);
  }

  SecenekKaydi _kayda(
    SecenekTipi tip,
    DocumentSnapshot<Map<String, dynamic>> anlik,
  ) => SecenekKaydi(
    secenek: Secenek.fromMap(
      anlik.id,
      tip,
      firestoreHaritasi(anlik.data()),
    ),
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

/// Giriş yapmış kullanıcının tür, çeşit ve anaç listeleri.
final secenekRepositorySaglayici = Provider<SecenekRepository>((ref) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.oturumYok();

  return SecenekRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});
