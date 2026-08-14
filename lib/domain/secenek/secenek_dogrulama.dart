/// Tür, çeşit ve anaç listelerinin form doğrulaması.
///
/// Hata varsa Türkçe mesaj, geçerliyse `null` döner — Flutter'ın
/// `TextFormField.validator` sözleşmesine uyar. Saf Dart olduğu için cihazsız
/// test edilir (bkz. KURALLAR.md §5.1, `UrunDogrulama`).
abstract final class SecenekDogrulama {
  /// Tek alan, tek kural: boş olamaz.
  ///
  /// Uzunluk alt sınırı **yok**. Ürün türünde iki karakter isteniyor ama bu
  /// listelerde tek harflik anaç gerçek: `A`, `B`, `M9`. Sınır koymak
  /// kullanıcının gerçek verisini reddederdi.
  static String? ad(String? deger) =>
      (deger ?? '').trim().isEmpty ? 'Bir ad yazın.' : null;
}
