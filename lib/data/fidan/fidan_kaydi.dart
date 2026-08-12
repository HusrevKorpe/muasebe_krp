import '../../domain/fidan/fidan.dart';

/// Bir [Fidan] ile o kaydın eşitlenme durumu.
///
/// "Henüz sunucuya yazılmadı" bilgisi bir iş kuralı değil, veri katmanının
/// durumudur; bu yüzden [Fidan] modelinin içinde değil, onu saran bu tiptedir
/// (bkz. `CariKaydi`).
class FidanKaydi {
  const FidanKaydi({required this.fidan, this.beklemede = false});

  final Fidan fidan;

  /// Kayıt yerel önbellekte bekliyor, sunucu henüz onaylamadı.
  final bool beklemede;

  @override
  bool operator ==(Object other) =>
      other is FidanKaydi &&
      other.fidan == fidan &&
      other.beklemede == beklemede;

  @override
  int get hashCode => Object.hash(fidan, beklemede);

  @override
  String toString() => 'FidanKaydi(${fidan.id}, beklemede: $beklemede)';
}
