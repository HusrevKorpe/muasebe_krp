/// Cari listesinin süzgeci — listede hangi cariler görünüyor.
///
/// Kişiler ekranı iki sekme: tamamı ve hesabı kapanmamış olanlar. Ölçüt
/// bakiyenin sıfırdan farklı olması; yön ayrımı yok. Cariye borçlu olduğumuz
/// hesap da carinin bize borçlu olduğu hesap da açıktır (bkz. KURALLAR.md §3.4).
enum CariSuzgeci {
  /// Aktif carilerin tamamı — bakiyesi sıfır olanlar dâhil.
  tumu,

  /// Yalnızca bakiyesi sıfır olmayanlar.
  acikHesap;

  bool get acikHesapMi => this == CariSuzgeci.acikHesap;
}
