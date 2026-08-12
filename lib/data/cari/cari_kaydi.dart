import '../../domain/cari/cari.dart';

/// Bir [Cari] ile o kaydın eşitlenme durumu.
///
/// "Henüz sunucuya yazılmadı" bilgisi bir iş kuralı değil, veri katmanının
/// durumudur; bu yüzden [Cari] modelinin içinde değil, onu saran bu tiptedir.
/// Kullanıcı serada internetsizken cari eklediğinde listede bunu görmesi gerekir
/// (bkz. KURALLAR.md §4.4).
class CariKaydi {
  const CariKaydi({required this.cari, this.beklemede = false});

  final Cari cari;

  /// Kayıt yerel önbellekte bekliyor, sunucu henüz onaylamadı.
  final bool beklemede;

  @override
  bool operator ==(Object other) =>
      other is CariKaydi && other.cari == cari && other.beklemede == beklemede;

  @override
  int get hashCode => Object.hash(cari, beklemede);

  @override
  String toString() => 'CariKaydi(${cari.id}, beklemede: $beklemede)';
}
