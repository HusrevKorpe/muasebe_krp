import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../core/log/log.dart';
import '../../domain/cari/cari.dart';
import '../../domain/fidan/fidan.dart';
import '../../domain/islem/islem.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';

/// `isletmeler/{isletmeId}` ağacının tamamını silen repository.
///
/// Yalnızca hesap silme akışında kullanılır. Muhasebe kaydının silinmemesi
/// kuralı (KURALLAR.md §4.2) tek bir işlemin sessizce yok edilmesiyle ilgilidir;
/// kullanıcının kendi hesabını ve tüm verisini kapatması Apple'ın da zorunlu
/// tuttuğu ayrı bir haktır (bkz. fazlar/faz-5-magaza.md).
///
/// Silme sunucu tarafında yapılmak zorunda: Firestore alt koleksiyonları üst
/// belge silinince kendiliğinden gitmez, tek tek dolaşılır.
class IsletmeVerisiRepository {
  const IsletmeVerisiRepository({
    required FirebaseFirestore firestore,
    required String isletmeId,
  }) : _firestore = firestore,
       _isletmeId = isletmeId;

  /// Tek yığında silinecek belge sayısı. Firestore'un `WriteBatch` sınırı 500;
  /// altında kalmak, sınırı zorlayan bir kenar durumu bırakmıyor.
  static const int _yiginBoyu = 300;

  /// Silinecek belgeler **sunucudan** okunur. Varsayılan kaynak çevrimdışıyken
  /// önbelleğe düşer; o zaman silinmiş sanılan belge sunucuda kalırdı. Bağlantı
  /// yoksa okuma hata verir ve akış hesabı silmeden durur.
  static const GetOptions _sunucudan = GetOptions(source: Source.server);

  final FirebaseFirestore _firestore;
  final String _isletmeId;

  DocumentReference<Map<String, dynamic>> get _isletmeBelgesi =>
      _firestore.collection(Isletme.koleksiyon).doc(_isletmeId);

  /// Cariler, işlemler, fidanlar ve işletme profilini bu sırayla siler.
  ///
  /// Yazma future'ları burada **beklenir** — repository'lerin geri kalanının
  /// aksine (KURALLAR.md §4.4). Sebep: bir sonraki adım hesabı silmek ve hesap
  /// gidince veriye erişim kalmıyor. Kuyruğa alınmış silmelerin sunucuya
  /// ulaşacağının garantisi yok.
  Future<void> tumVeriyiSil() async {
    try {
      await _carileriSil();
      await _koleksiyonuSil(_isletmeBelgesi.collection(Fidan.koleksiyon));
      await _isletmeBelgesi.delete();
    } on FirebaseException catch (hata, yigin) {
      Log.hata('Hesap verisi silinemedi: ${hata.code}', hata, yigin);
      throw const VeriHatasi.silinemedi();
    }
  }

  /// Her cariyi önce işlemlerinden arındırır, sonra siler.
  ///
  /// Sayfalamada imleç gerekmiyor: okunan yığın silindiği için bir sonraki
  /// sorgu kaldığı yerden devam eder ve koleksiyon boşalınca döngü biter.
  Future<void> _carileriSil() async {
    final cariler = _isletmeBelgesi.collection(Cari.koleksiyon);

    while (true) {
      final anlik = await cariler.limit(_yiginBoyu).get(_sunucudan);
      if (anlik.docs.isEmpty) return;

      for (final cari in anlik.docs) {
        await _koleksiyonuSil(cari.reference.collection(Islem.koleksiyon));
      }

      final yigin = _firestore.batch();
      for (final cari in anlik.docs) {
        yigin.delete(cari.reference);
      }
      await yigin.commit();
    }
  }

  Future<void> _koleksiyonuSil(
    CollectionReference<Map<String, dynamic>> koleksiyon,
  ) async {
    while (true) {
      final anlik = await koleksiyon.limit(_yiginBoyu).get(_sunucudan);
      if (anlik.docs.isEmpty) return;

      final yigin = _firestore.batch();
      for (final belge in anlik.docs) {
        yigin.delete(belge.reference);
      }
      await yigin.commit();
    }
  }
}

final isletmeVerisiRepositorySaglayici = Provider<IsletmeVerisiRepository>((
  ref,
) {
  final isletmeId = ref.watch(isletmeKimligiSaglayici);
  if (isletmeId == null) throw const VeriHatasi.yetkisiz();

  return IsletmeVerisiRepository(
    firestore: ref.watch(firestoreSaglayici),
    isletmeId: isletmeId,
  );
});
