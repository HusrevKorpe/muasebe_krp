/// Kullanıcının seçtiği tema. Cihazda saklanır.
///
/// Yalnızca iki değer var; "sistem ayarına uy" diye üçüncü bir seçenek
/// **bilerek yok**. Uygulama gün içinde tarlada ve seranın gölgesinde
/// kullanılıyor; kullanıcı temayı iOS'un otomatik geçişine bırakmak yerine
/// kendisi sabitlemek istedi. Üç seçenek olsaydı ayarda tek bir anahtar
/// yetmez, liste gerekirdi.
///
/// Tercih ortak deftere değil cihaza yazılır: defteri iki kişi paylaşıyor ama
/// telefonu paylaşmıyorlar (bkz. `TemaRepository`).
enum TemaTercihi {
  acik(kod: 'acik'),
  koyu(kod: 'koyu');

  const TemaTercihi({required this.kod});

  /// Cihaza yazılan değer.
  ///
  /// Enum'ın `name` alanı yerine açıkça yazılıyor: alan adı değişirse
  /// kaydedilmiş tercih sessizce eşleşmez olurdu (bkz. `SecenekTipi.anahtar`).
  final String kod;

  /// Hiç seçim yapılmamışsa uygulanan tema.
  ///
  /// Açık tema esas tasarım: palet krem zemin üzerine kurgulandı, ekran
  /// güneşte de okunuyor.
  static const TemaTercihi varsayilan = acik;

  /// Cihazdan okunan kodu tercihe çevirir.
  ///
  /// Tanınmayan ya da eksik değer [varsayilan]'a düşer — burada `null` dönmek
  /// çağıranı aynı kararı ikinci kez vermeye zorlardı.
  static TemaTercihi koddan(String? kod) {
    for (final tercih in values) {
      if (tercih.kod == kod) return tercih;
    }
    return varsayilan;
  }

  bool get koyuMu => this == koyu;
}
