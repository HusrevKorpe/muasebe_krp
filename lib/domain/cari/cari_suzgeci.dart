import 'cari_grubu.dart';

/// Cari listesinin süzgeci — Kişiler ekranındaki üç sekme.
///
/// İlk ikisi kişileri grubuna göre ayırır ([CariGrubu]); üçüncüsü grup
/// gözetmeden hesabı kapanmamış olanları toplar. Ölçüt bakiyenin sıfırdan
/// farklı olması; yön ayrımı yok. Cariye borçlu olduğumuz hesap da carinin bize
/// borçlu olduğu hesap da açıktır (bkz. KURALLAR.md §3.4).
enum CariSuzgeci {
  /// Fidancı işaretlenmemiş herkes — sıradan müşteriler.
  musteriler,

  /// Yalnızca fidancı işaretlenmiş meslektaşlar.
  fidancilar,

  /// Her iki gruptan, bakiyesi sıfır olmayanlar.
  acikHesap;

  bool get acikHesapMi => this == CariSuzgeci.acikHesap;

  /// Sunucu sorgusuna eklenecek grup eşitliği; gerekmiyorsa `null`.
  ///
  /// Yalnızca fidancı listesi sunucuda süzülüyor. Müşteri listesi için
  /// `grup == 'musteri'` yazılamaz: Firestore'un eşitlik süzgeci alanı **hiç
  /// olmayan** belgeyi eşleştirmez ve bu özellikten önce kaydedilmiş her kişi
  /// listeden düşerdi. Göç scripti yerine eldeki ayıklama seçildi — katalogda
  /// olduğu gibi eski şema okunmaya devam ediyor (bkz. [kayitGirerMi]).
  CariGrubu? get sunucuGrubu =>
      this == CariSuzgeci.fidancilar ? CariGrubu.fidanci : null;

  /// Sunucudan gelen kayıt listede kalacak mı.
  ///
  /// Yalnızca müşteri sekmesinde iş yapar: fidancıları eleyen adım budur.
  /// Fidancı sayısı azdır — kullanıcı bir avuç meslektaşını işaretliyor — ve
  /// sayfalama bundan etkilenmez: `dahaVar` ham belge sayısına bakar, ekranı
  /// doldurmayan sayfa da `CariListeGorunumu` tarafından tamamlanır.
  bool kayitGirerMi(CariGrubu grup) =>
      this != CariSuzgeci.musteriler || grup == CariGrubu.musteri;
}
