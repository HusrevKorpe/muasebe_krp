import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore belgesini domain'in beklediği saf Dart haritasına çevirir.
///
/// Firestore tarih alanlarını [Timestamp] olarak döner. `lib/domain/` içinde
/// hiçbir Firestore tipi görünemeyeceği için (bkz. KURALLAR.md §1.3) dönüşüm
/// burada, veri katmanının sınırında yapılır. Gömülü haritalar ve diziler de
/// gezilir; `bankaHesaplari` gibi iç içe yapılarda tarih kalırsa model onu
/// sessizce `null` okurdu.
Map<String, Object?> firestoreHaritasi(Map<String, Object?>? veri) {
  if (veri == null) return const <String, Object?>{};
  return <String, Object?>{
    for (final giris in veri.entries) giris.key: _degeriCevir(giris.value),
  };
}

Object? _degeriCevir(Object? deger) {
  if (deger is Timestamp) return deger.toDate();
  if (deger is Map) {
    return <String, Object?>{
      for (final giris in deger.entries)
        giris.key.toString(): _degeriCevir(giris.value),
    };
  }
  if (deger is Iterable) {
    return deger.map(_degeriCevir).toList(growable: false);
  }
  return deger;
}
