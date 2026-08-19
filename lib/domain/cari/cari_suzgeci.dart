import 'cari_grubu.dart';

/// Cari listesinin süzgeci.
///
/// İlk üçü Kişiler ekranındaki sekmeler: ikisi kişileri grubuna göre ayırır
/// ([CariGrubu]), üçüncüsü grup gözetmeden hesabı kapanmamış olanları toplar.
/// Ölçüt bakiyenin sıfırdan farklı olması; yön ayrımı yok. Cariye borçlu
/// olduğumuz hesap da carinin bize borçlu olduğu hesap da açıktır
/// (bkz. KURALLAR.md §3.4).
///
/// Dördüncüsü sekme değil, Ayarlar'dan açılan ayrı bir sayfa: listeden
/// kaldırılmış (pasif) kişiler. Aynı süzgeç enum'ında duruyor çünkü sorgusu,
/// sayfalaması ve araması ötekilerle birebir aynı — tek farkı `aktif` alanının
/// değeri.
enum CariSuzgeci {
  /// Fidancı işaretlenmemiş herkes — sıradan müşteriler.
  musteriler,

  /// Yalnızca fidancı işaretlenmiş meslektaşlar.
  fidancilar,

  /// Her iki gruptan, bakiyesi sıfır olmayanlar.
  acikHesap,

  /// Listeden kaldırılmış kişiler — `aktif == false`. İki gruptan da gelir.
  pasifler;

  bool get acikHesapMi => this == CariSuzgeci.acikHesap;

  /// Liste pasif kayıtları mı gösteriyor. Sorgudaki `aktif` eşitliğinin değeri
  /// bundan çıkar: pasif listede `false`, ötekilerde `true`.
  bool get pasifMi => this == CariSuzgeci.pasifler;

  /// Listede iki grup birlikte mi geliyor. Satırdaki "Fidancı" rozeti yalnızca
  /// burada anlamlı; kendi sekmesinde her satıra aynı rozeti basmak bilgi
  /// vermez.
  bool get gruplarKarisikMi => acikHesapMi || pasifMi;

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
