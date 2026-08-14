/// Fidan kimliğinin üç parçası. Her parçanın kendi listesi vardır.
///
/// **Neden ürün katalogu yetmedi:** katalogdaki kayıt *tam kombinasyondur*
/// (`Elma Scarlet M9`). Olası kombinasyon sayısı türlerin, çeşitlerin ve
/// anaçların çarpımı kadardır; kullanıcı hepsini tek tek giremiyor ve pratikte
/// üç kutuyu her satışta elle yazıyordu. Üç küçük liste, bir çarpım tablosunun
/// yerini tutuyor: anaçlar bir kez giriliyor, fatura keserken tıklanıyor.
///
/// Ürün katalogu **kalkmadı**: fiyat ön dolgusunu ve kalemin `urunId` bağını o
/// veriyor (bkz. `Urun`). İki yol yan yana duruyor.
enum SecenekTipi {
  tur(anahtar: 'tur', koleksiyon: 'turler'),
  cesit(anahtar: 'cesit', koleksiyon: 'cesitler'),
  anac(anahtar: 'anac', koleksiyon: 'anaclar');

  const SecenekTipi({required this.anahtar, required this.koleksiyon});

  /// Gezinme yolundaki değer: `/listeler/anac`.
  ///
  /// Enum'ın `name` alanı yerine açıkça yazılır: alan adı değiştirilirse
  /// kaydedilmiş bir yol sessizce eşleşmez olurdu (bkz. `IslemTipi.anahtar`).
  final String anahtar;

  /// Firestore koleksiyon adı.
  ///
  /// Tip belgeye **alan olarak yazılmaz**, koleksiyon adı taşır. Tek koleksiyon
  /// + `tip` alanı olsaydı liste sorgusu `tip == x` süzgecini `aramaAnahtari`
  /// sıralamasıyla birleştirir ve bileşik index isterdi. Ayrı koleksiyonda
  /// Firestore'un tek alan için kendiliğinden ürettiği index yetiyor; bu yüzden
  /// `firestore.indexes.json` bu özellik için hiç değişmedi (KURALLAR.md §4.3).
  final String koleksiyon;

  /// Gezinme yolundan okunan değeri tipe çevirir. Tanınmayan değer `null`.
  static SecenekTipi? anahtardan(String? anahtar) {
    for (final tip in values) {
      if (tip.anahtar == anahtar) return tip;
    }
    return null;
  }
}
