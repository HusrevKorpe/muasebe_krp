import '../../domain/urun/urun.dart';

/// Bir [Urun] ile o kaydın eşitlenme durumu.
///
/// "Henüz sunucuya yazılmadı" bilgisi bir iş kuralı değil, veri katmanının
/// durumudur; bu yüzden [Urun] modelinin içinde değil, onu saran bu tiptedir
/// (bkz. `CariKaydi`).
class UrunKaydi {
  const UrunKaydi({required this.urun, this.beklemede = false});

  final Urun urun;

  /// Kayıt yerel önbellekte bekliyor, sunucu henüz onaylamadı.
  final bool beklemede;

  @override
  bool operator ==(Object other) =>
      other is UrunKaydi && other.urun == urun && other.beklemede == beklemede;

  @override
  int get hashCode => Object.hash(urun, beklemede);

  @override
  String toString() => 'UrunKaydi(${urun.id}, beklemede: $beklemede)';
}
