import '../../core/metin/metinler.dart';

/// Fidanın kök tipi.
///
/// Referans ekstrede kalem adlarının içine gömülü geçiyor: `Hachiya Tüplü`.
/// Serbest metinde kalırsa aynı fidan "tüplü", "Tüplü" ve "tuplu" olarak üç
/// ayrı kayda dönüşür; bu yüzden ayrı bir alan ve sayılı bir tip.
///
/// Alan **isteğe bağlıdır**: çıplak kök mü tüplü mü bilmeden de fidan
/// tanımlanabilir (bkz. `fazlar/faz-3-katalog.md`).
enum KokTipi {
  tuplu(anahtar: 'tuplu', ad: Metinler.kokTipiTuplu),
  ciplakKok(anahtar: 'ciplakKok', ad: Metinler.kokTipiCiplakKok);

  const KokTipi({required this.anahtar, required this.ad});

  /// Firestore'a yazılan değer.
  ///
  /// Enum'ın `name` alanı yerine açıkça yazılır: sabit adı değiştirilirse
  /// veritabanındaki geçmiş kayıtlar sessizce okunamaz hâle gelirdi
  /// (bkz. `IslemTipi.anahtar`).
  final String anahtar;

  /// Kullanıcıya gösterilen ad. Görünen fidan adının parçası olduğu için
  /// görünüm katmanında değil burada duruyor — bkz. `Fidan.goruntuAdi`.
  final String ad;

  /// Firestore'dan okunan değeri tipe çevirir. Tanınmayan değer için `null`.
  static KokTipi? anahtardan(String? anahtar) {
    for (final tip in values) {
      if (tip.anahtar == anahtar) return tip;
    }
    return null;
  }
}
