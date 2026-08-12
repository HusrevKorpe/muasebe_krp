/// Kullanıcının kalem tutarını hangi uçtan girdiği.
///
/// İki mod da zorunludur, çünkü kullanıcı yuvarlak toplam üzerinden çalışır.
/// Referans ekstredeki Hurma kalemi `1.650 Adet × 18,79 ₺` yazıyor ama
/// `1.650 × 18,79 = 31.003,50`; gerçek toplam `31.000 ₺` ve birim fiyat oradan
/// geri hesaplanmış. Yalnızca [birimFiyat] modu sunulsaydı kullanıcının faturası
/// tutmazdı (bkz. `fazlar/faz-2-islemler.md`).
enum KalemGirisModu {
  /// Kullanıcı birim fiyatı girer, tutar çarpımla bulunur — sonuç tamdır.
  birimFiyat,

  /// Kullanıcı toplam tutarı girer, birim fiyat geriye hesaplanır ve
  /// **girilen toplam esas alınır** (bkz. KURALLAR.md §3.2).
  toplam,
}
