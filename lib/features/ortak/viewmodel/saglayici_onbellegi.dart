import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `autoDispose` sağlayıcıyı son dinleyicisi gittikten sonra [sure] kadar daha
/// hayatta tutar.
///
/// Sağlayıcı ekrandan çıkar çıkmaz atılırsa geri dönüşte her şey sıfırdan
/// kurulur: ekran spinner'a düşer ve Firestore dinleyicisi yeniden açılır —
/// oysa veri telefonun önbelleğinde durmaktadır. Kullanıcı listeyle detay
/// arasında sürekli gidip gelir; bu pencere o gidiş gelişi bedavaya çevirir.
///
/// Süre sonsuz değil: her ziyaret edilen cari için açık kalan bir Firestore
/// dinleyicisi birikir. Pencere kapanınca dinleyici kapanır, okuma ücreti
/// işlemez ve bellek boşalır.
void birSureSakla(Ref ref, {Duration sure = const Duration(minutes: 5)}) {
  final baglanti = ref.keepAlive();
  final zamanlayici = Timer(sure, baglanti.close);
  ref.onDispose(zamanlayici.cancel);
}
