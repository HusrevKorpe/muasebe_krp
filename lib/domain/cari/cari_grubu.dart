/// Kişinin hangi listede durduğu: sıradan müşteri mi, meslektaş fidancı mı.
///
/// Kullanıcının isteği: *"fidancılarla sürekli alışveriş oluyor, birbirimizden
/// alıp veriyoruz; normal müşteriye bir kere fidan verdiğimde o kalıyor. Ama
/// fidancıları başka bir sekmede yapalım."* İki grubun muhasebesi **aynıdır** —
/// fatura, tahsilat, bakiye ve ekstre hiç değişmez; ayrılan yalnızca listedir.
/// Bu yüzden grup ayrı bir koleksiyon değil, cari üzerinde tek bir alandır:
/// bugün müşteri diye kayıtlı biri yarın fidancı işaretlenince geçmişi yerinde
/// kalır.
///
/// Bir kişi tek gruba aittir; hem müşteri hem fidancı olmaz.
enum CariGrubu {
  musteri(anahtar: 'musteri'),
  fidanci(anahtar: 'fidanci');

  const CariGrubu({required this.anahtar});

  /// Firestore'a yazılan değer.
  ///
  /// Enum'ın `name` alanı yerine açıkça yazılır: alan adı değiştirilirse
  /// veritabanındaki kayıtlar sessizce başka gruba düşerdi
  /// (bkz. `IslemTipi.anahtar`).
  final String anahtar;

  /// Alanı hiç yazılmamış belgenin grubu.
  static const CariGrubu varsayilan = CariGrubu.musteri;

  bool get fidanciMi => this == CariGrubu.fidanci;

  /// Firestore'dan okunan değeri gruba çevirir.
  ///
  /// Alanı olmayan belge de tanınmayan değer de [varsayilan] sayılır: bu
  /// özellikten önce kaydedilmiş her kişi müşteridir ve öyle kalmalıdır
  /// (kullanıcının kararı: *"hepsi müşteri olarak başlasın, ben işaretlerim"*).
  static CariGrubu anahtardan(String? anahtar) {
    for (final grup in values) {
      if (grup.anahtar == anahtar) return grup;
    }
    return varsayilan;
  }
}
