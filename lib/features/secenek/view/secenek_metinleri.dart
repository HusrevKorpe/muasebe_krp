import '../../../core/metin/metinler.dart';
import '../../../domain/secenek/secenek_tipi.dart';

/// [SecenekTipi]'nin ekranda görünen karşılıkları.
///
/// Eşleme domain'de değil view katmanında duruyor: `lib/domain/` altında
/// kullanıcıya görünen metin taşınmıyor ve metinlerin tamamı [Metinler]'den
/// geliyor (KURALLAR.md §1.3, §6). Enum'a etiket alanı eklemek domain'i
/// arayüz metnine bağlardı.
extension SecenekTipiMetinleri on SecenekTipi {
  /// Kutunun etiketi: `Anaç`.
  String get etiket => switch (this) {
    SecenekTipi.tur => Metinler.tur,
    SecenekTipi.cesit => Metinler.cesit,
    SecenekTipi.anac => Metinler.anac,
  };

  /// Kutunun ipucu metni: `M9`.
  String get ipucu => switch (this) {
    SecenekTipi.tur => Metinler.turIpucu,
    SecenekTipi.cesit => Metinler.cesitIpucu,
    SecenekTipi.anac => Metinler.anacIpucu,
  };

  /// Liste ekranının başlığı: `Anaçlar`.
  String get listeBasligi => switch (this) {
    SecenekTipi.tur => Metinler.turler,
    SecenekTipi.cesit => Metinler.cesitler,
    SecenekTipi.anac => Metinler.anaclar,
  };

  /// Seçim sayfasının başlığı: `Anaç Seç`.
  String get secimBasligi => switch (this) {
    SecenekTipi.tur => Metinler.turSec,
    SecenekTipi.cesit => Metinler.cesitSec,
    SecenekTipi.anac => Metinler.anacSec,
  };
}
