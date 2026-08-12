/// `fromMap` dönüşümleri için güvenli alan okuyucuları.
///
/// Firestore'dan gelen belge şemasız bir `Map`'tir: alan hiç olmayabilir, `null`
/// olabilir ya da beklenenden farklı tipte gelebilir (eski sürümde `double`
/// yazılmış bir tutar gibi). Doğrudan `veri['ad'] as String` yazmak bu üç durumda
/// da çalışma anında patlar. Model sınıfları alanlarını bu fonksiyonlarla okur.
///
/// Bu dosya saf Dart'tır; `Timestamp` gibi Firestore tipleri buraya ulaşmadan
/// önce `data/` katmanında [DateTime]'a çevrilir — bkz. KURALLAR.md §1.3.
library;

/// Zorunlu metin alanı. Alan yoksa ya da metin değilse [varsayilan] döner.
String haritaMetin(
  Map<String, Object?> veri,
  String alan, {
  String varsayilan = '',
}) {
  final deger = veri[alan];
  return deger is String ? deger : varsayilan;
}

/// İsteğe bağlı metin alanı. Boş metin `null` sayılır — kullanıcı bir alanı
/// silip kaydettiğinde geriye boş dize kalmasın diye.
String? haritaMetinOpsiyonel(Map<String, Object?> veri, String alan) {
  final deger = veri[alan];
  if (deger is! String) return null;
  final kirpilmis = deger.trim();
  return kirpilmis.isEmpty ? null : kirpilmis;
}

/// Tam sayı alanı. Parasal değerler buradan geçer, bu yüzden `double` gelirse
/// yuvarlanarak alınır — sessizce sıfırlanmaz (bkz. KURALLAR.md §3.1).
int haritaTamSayi(
  Map<String, Object?> veri,
  String alan, {
  int varsayilan = 0,
}) {
  final deger = veri[alan];
  if (deger is int) return deger;
  if (deger is double) return deger.round();
  return varsayilan;
}

bool haritaMantiksal(
  Map<String, Object?> veri,
  String alan, {
  bool varsayilan = false,
}) {
  final deger = veri[alan];
  return deger is bool ? deger : varsayilan;
}

DateTime? haritaTarih(Map<String, Object?> veri, String alan) {
  final deger = veri[alan];
  return deger is DateTime ? deger : null;
}

/// Belge içindeki nesne dizisini okur: `bankaHesaplari` gibi.
/// Beklenen biçimde olmayan öğeler atlanır.
List<Map<String, Object?>> haritaListesi(
  Map<String, Object?> veri,
  String alan,
) {
  final deger = veri[alan];
  if (deger is! List) return const <Map<String, Object?>>[];
  return deger
      .whereType<Map<Object?, Object?>>()
      .map(
        (oge) => <String, Object?>{
          for (final giris in oge.entries)
            if (giris.key is String) giris.key! as String: giris.value,
        },
      )
      .toList(growable: false);
}
