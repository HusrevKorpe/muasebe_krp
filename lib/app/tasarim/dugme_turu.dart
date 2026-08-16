/// Bir düğmenin görsel ağırlığı.
///
/// Sıralama bir hiyerarşi: bir ekranda **en fazla bir** [birincil] düğme olur.
/// İki dolu düğme yan yana durduğunda kullanıcı hangisinin asıl eylem olduğunu
/// okuyamıyor; ikincisi [ikincil] ya da [sade] olmalı.
enum DugmeTuru {
  /// Ekranın asıl eylemi: Kaydet, Giriş yap, Ekle. Dolu zemin, ana renk.
  birincil,

  /// Yardımcı eylem: Üründen seç, Banka hesabı ekle. Çerçeveli, zeminsiz.
  ikincil,

  /// Taşıyıcı olmayan eylem: Vazgeç, Satır ekle. Yalnızca metin.
  sade,

  /// Yıkıcı eylemin onayı: onay kutusundaki "Sil". Dolu zemin, hata rengi.
  tehlikeli,

  /// Yıkıcı eylemin kendisi: form içindeki "Sil". Zeminsiz, hata renginde metin.
  ///
  /// [tehlikeli]'den ayrı: silme *önerisi* ile silme *onayı* aynı ağırlıkta
  /// görünmemeli — kutuyu açan düğme sessiz, kutudaki düğme yüksek sesli.
  tehlikeliSade,
}
