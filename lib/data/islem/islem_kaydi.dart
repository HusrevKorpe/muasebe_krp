import '../../domain/islem/islem.dart';

/// Bir [Islem] ile o kaydın eşitlenme durumu.
///
/// "Henüz sunucuya yazılmadı" bilgisi bir iş kuralı değil, veri katmanının
/// durumudur; bu yüzden [Islem] modelinin içinde değil onu saran bu tiptedir.
/// Kullanıcı tarlada internetsizken fatura girdiğinde listede bunu görmeli
/// (bkz. KURALLAR.md §4.4).
class IslemKaydi {
  const IslemKaydi({required this.islem, this.beklemede = false});

  final Islem islem;

  /// Kayıt yerel önbellekte bekliyor, sunucu henüz onaylamadı.
  final bool beklemede;

  @override
  bool operator ==(Object other) =>
      other is IslemKaydi &&
      other.islem.id == islem.id &&
      other.beklemede == beklemede;

  @override
  int get hashCode => Object.hash(islem.id, beklemede);

  @override
  String toString() => 'IslemKaydi(${islem.id}, beklemede: $beklemede)';
}
