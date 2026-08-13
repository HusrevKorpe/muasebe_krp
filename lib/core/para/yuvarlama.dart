import 'kurus.dart';

/// Tam sayı bölme; sonucu en yakın tam sayıya yuvarlar, yarımı sıfırdan uzağa atar.
///
/// `double`'a hiç düşmez — bölme sırasında kayan nokta sapması oluşmaz.
/// Bkz. KURALLAR.md §3.2.
int bolVeYuvarla(int pay, int payda) {
  if (payda == 0) {
    throw ArgumentError.value(payda, 'payda', 'Sıfıra bölme yapılamaz');
  }
  final negatifMi = (pay < 0) != (payda < 0);
  final mutlakPay = pay.abs();
  final mutlakPayda = payda.abs();
  final sonuc = (mutlakPay + mutlakPayda ~/ 2) ~/ mutlakPayda;
  return negatifMi ? -sonuc : sonuc;
}

/// Birim fiyatı toplam tutardan geriye hesaplar.
///
/// Kullanıcı yuvarlak toplam üzerinden çalışır: "Hurma 1.650 adet, toplam 31.000 ₺".
/// Birim fiyat buradan `18,79 ₺` olarak türetilir — ama **fatura tutarı girilen
/// toplam olarak kalır**, yuvarlanmış birim fiyattan yeniden çarpılmaz.
/// Aksi hâlde `1.650 × 18,79 = 31.003,50` çıkar ve fatura tutmaz.
Kurus birimFiyatHesapla({required Kurus toplam, required int miktar}) {
  if (miktar <= 0) {
    throw ArgumentError.value(miktar, 'miktar', 'Miktar sıfırdan büyük olmalı');
  }
  return Kurus(bolVeYuvarla(toplam.deger, miktar));
}

/// Miktar ve birim fiyattan kalem tutarını hesaplar. Yuvarlama gerekmez —
/// iki tam sayının çarpımı tamdır.
Kurus kalemTutari({required int miktar, required Kurus birimFiyat}) {
  if (miktar < 0) {
    throw ArgumentError.value(miktar, 'miktar', 'Miktar negatif olamaz');
  }
  return birimFiyat * miktar;
}
