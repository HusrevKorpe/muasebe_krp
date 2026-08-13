/// Cari listesinin sıralama ölçütü — repository'nin `listele` parametresi.
///
/// Ekranda seçim yok; liste her zaman [ad] ile gelir. Diğer ölçütler
/// repository'de duruyor, çağrı yeri açıkça isterse kullanılabilir.
///
/// Her ölçüt Firestore'da ayrı bir bileşik index gerektirir; yeni bir değer
/// eklenirse `firestore.indexes.json` da güncellenmelidir (bkz. KURALLAR.md §4.3).
enum CariSiralamasi {
  /// Ada göre A→Z. Arama yapılırken zorunlu ölçüt budur: Firestore'da aralık
  /// süzgeci uygulanan alan ilk sıralama alanı olmak zorundadır.
  ad,

  /// Borcu en yüksek olan başta.
  bakiye,

  /// En son işlem görmüş cari başta.
  sonIslem,
}
