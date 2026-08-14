import '../../domain/secenek/secenek.dart';

/// Bir [Secenek] ile o kaydın eşitlenme durumu.
///
/// "Henüz sunucuya yazılmadı" bilgisi bir iş kuralı değil, veri katmanının
/// durumudur; bu yüzden [Secenek] modelinin içinde değil, onu saran bu tiptedir
/// (bkz. `UrunKaydi`).
class SecenekKaydi {
  const SecenekKaydi({required this.secenek, this.beklemede = false});

  final Secenek secenek;

  /// Kayıt yerel önbellekte bekliyor, sunucu henüz onaylamadı.
  final bool beklemede;

  @override
  bool operator ==(Object other) =>
      other is SecenekKaydi &&
      other.secenek == secenek &&
      other.beklemede == beklemede;

  @override
  int get hashCode => Object.hash(secenek, beklemede);

  @override
  String toString() => 'SecenekKaydi(${secenek.id}, beklemede: $beklemede)';
}
