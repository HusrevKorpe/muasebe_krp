import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore akışını dinleyen liste ViewModel'leri için ortak taban.
///
/// ## Neden `get()` değil `snapshots()`
///
/// `get()` varsayılan olarak sunucuya gider ve cevabını bekler; telefonun
/// önbelleğindeki veriyi ancak SDK "çevrimdışıyım" kararını verdikten sonra
/// kullanır. Bağlantı kopuk değil de **yavaşsa** o karar hiç verilmez ve ekran
/// dakikalarca dönebilir. `snapshots()` ise önce önbellekten anında yayar,
/// sunucu cevabı gelince ikinci kez yayar: kaydedilen satır ağ beklemeden
/// listede belirir ve ortak defterin öteki telefonundan girilen kayıt da
/// kendiliğinden düşer (bkz. KURALLAR.md §4.3).
///
/// ## Sayfalama neden imleçle değil sınırla
///
/// `startAfter` sabit bir belgeye bakar; canlı akışta o belge yer değiştirince
/// imleç kayar. Bunun yerine sorgunun `limit`'i bir sayfa büyütülüp akışa
/// yeniden abone olunur ([sayfaEkle]). Eldeki kayıtlar önbellekten anında geri
/// gelir; Firestore'dan ücreti işleyen okuma yalnızca yeni sayfa kadardır.
///
/// [D] ekranın durumu, [S] repository'nin yaydığı sayfa tipidir.
abstract class AkisListesiViewModel<D, S> extends AsyncNotifier<D> {
  StreamSubscription<S>? _abone;
  int _sinir = 0;

  /// Bir "daha yükle" adımında sınıra eklenen kayıt sayısı.
  int get sayfaBoyu;

  /// Şu anda dinlenen kayıt sınırı.
  int get sinir => _sinir;

  /// [sinir] kadar kaydı canlı yayan akışı kurar.
  Stream<S> akisKur(int sinir);

  /// Akıştan gelen sayfayı ekran durumuna çevirir.
  D durumaCevir(S sayfa);

  /// Akış hata verdiğinde eldeki kayıtları koruyan durum.
  ///
  /// Liste ekranda kalmalı, kullanıcı yalnızca devamını kaybetmeli — bu yüzden
  /// hata `AsyncValue.error` yerine durumun içindeki hata satırına yazılır.
  D hataliDurum(D mevcut, Object hata);

  /// `build()` içinde çağrılır: aboneliği ilk sayfayla kurar ve sağlayıcı
  /// kapanınca iptal edilmesini bağlar.
  Future<D> ilkBaglanti() {
    ref.onDispose(() => unawaited(_abone?.cancel()));
    return bastanBagla();
  }

  /// Sınırı ilk sayfaya döndürüp akışı yeniden kurar.
  ///
  /// Arama değiştiğinde ve aşağı çekerek yenilemede çağrılır.
  Future<D> bastanBagla() {
    _sinir = sayfaBoyu;
    return _bagla();
  }

  /// Sınırı bir sayfa büyütüp akışı yeniden kurar.
  Future<D> sayfaEkle() {
    _sinir += sayfaBoyu;
    return _bagla();
  }

  /// [baglanma]'yı yürütür ve sonucunu duruma yazar.
  ///
  /// Durum **`loading`'e düşürülmez**: eldeki liste ekranda kalır, yenisi
  /// gelince yerine geçer. Hata gelirse de kayıtlar silinmez; elde hiç kayıt
  /// yoksa hata ekranı gösterilir.
  Future<void> durumaYaz(Future<D> Function() baglanma) async {
    try {
      final durum = await baglanma();
      if (ref.mounted) state = AsyncValue<D>.data(durum);
    } catch (hata, yigin) {
      if (ref.mounted) _hatayiIsle(hata, yigin);
    }
  }

  /// Akışa abone olur; ilk değer gelene kadar tamamlanmayan bir future döner.
  ///
  /// Sonraki değerler doğrudan [state]'e yazılır. İlk değeri future'a, sonraki
  /// değerleri duruma yazmak yarışa yol açmaz: `Completer` tamamlandıktan sonra
  /// çağıranın onu duruma işlemesi bir microtask sürer, akışın sonraki olayı
  /// ise ancak bir sonraki olay döngüsü turunda gelir.
  Future<D> _bagla() {
    final ilkDeger = Completer<D>();
    unawaited(_abone?.cancel());

    _abone = akisKur(_sinir).listen(
      (sayfa) {
        final durum = durumaCevir(sayfa);
        if (ilkDeger.isCompleted) {
          if (ref.mounted) state = AsyncValue<D>.data(durum);
        } else {
          ilkDeger.complete(durum);
        }
      },
      onError: (Object hata, StackTrace yigin) {
        if (!ilkDeger.isCompleted) {
          ilkDeger.completeError(hata, yigin);
        } else if (ref.mounted) {
          _hatayiIsle(hata, yigin);
        }
      },
    );

    return ilkDeger.future;
  }

  void _hatayiIsle(Object hata, StackTrace yigin) {
    final mevcut = state.value;
    state = mevcut == null
        ? AsyncValue<D>.error(hata, yigin)
        : AsyncValue<D>.data(hataliDurum(mevcut, hata));
  }
}
