/// İşlemin teslim/geçerlilik durumu.
///
/// Muhasebe kaydı silinmez; yanlış giriş [iptal] ile işaretlenir ve bakiyeye
/// katkısı geri alınır (bkz. KURALLAR.md §4.2).
enum IslemDurumu {
  beklemede(anahtar: 'beklemede'),
  teslimEdildi(anahtar: 'teslimEdildi'),
  iptal(anahtar: 'iptal');

  const IslemDurumu({required this.anahtar});

  /// Firestore'a yazılan değer — bkz. `IslemTipi.anahtar`.
  final String anahtar;

  static IslemDurumu anahtardan(String? anahtar) {
    for (final durum in values) {
      if (durum.anahtar == anahtar) return durum;
    }
    return IslemDurumu.beklemede;
  }
}
