/// Cari listesinin sıralama ölçütü.
///
/// Her ölçüt Firestore'da ayrı bir bileşik index gerektirir; yeni bir değer
/// eklenirse `firestore.indexes.json` da güncellenmelidir (bkz. KURALLAR.md §4.3).
enum CariSiralamasi {
  /// Ada göre A→Z. Arama yapılırken zorunlu ölçüt budur: Firestore'da aralık
  /// süzgeci uygulanan alan ilk sıralama alanı olmak zorundadır.
  ad('Ada göre'),

  /// Borcu en yüksek olan başta.
  bakiye('Bakiyeye göre'),

  /// En son işlem görmüş cari başta.
  sonIslem('Son işleme göre');

  const CariSiralamasi(this.baslik);

  /// Sıralama menüsünde görünen Türkçe etiket.
  final String baslik;
}
