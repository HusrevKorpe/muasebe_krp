import '../../core/para/kurus.dart';
import 'islem.dart';

/// Ekstrenin bir satırı: işlem ve o işlemden **sonraki** yürüyen bakiye.
class BakiyeSatiri {
  const BakiyeSatiri({required this.islem, required this.yuruyenBakiye});

  final Islem islem;

  /// Bu işlem uygulandıktan sonraki bakiye. Referans ekstrenin "BAKİYE"
  /// kolonuna karşılık gelir.
  final Kurus yuruyenBakiye;

  @override
  bool operator ==(Object other) =>
      other is BakiyeSatiri &&
      other.islem.id == islem.id &&
      other.yuruyenBakiye == yuruyenBakiye;

  @override
  int get hashCode => Object.hash(islem.id, yuruyenBakiye);

  @override
  String toString() =>
      'BakiyeSatiri(${islem.id}, ${yuruyenBakiye.deger})';
}
