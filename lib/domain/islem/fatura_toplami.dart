import '../../core/para/kurus.dart';

/// Bir faturanın tutar dökümü: ara toplam → KDV → genel toplam.
class FaturaToplami {
  const FaturaToplami({
    required this.araToplam,
    required this.kdvOrani,
    required this.kdv,
    required this.toplam,
  });

  static const FaturaToplami bos = FaturaToplami(
    araToplam: Kurus.sifir,
    kdvOrani: 0,
    kdv: Kurus.sifir,
    toplam: Kurus.sifir,
  );

  /// Kalem tutarlarının toplamı.
  final Kurus araToplam;

  /// Yüzde olarak KDV oranı. `1` = %1, `0` = KDV yok.
  final int kdvOrani;

  final Kurus kdv;

  /// `araToplam + kdv`. Kaydedildikten sonra **saklanan tutar esastır**,
  /// geçmişe dönük yeniden hesaplanmaz (bkz. KURALLAR.md §3.2).
  final Kurus toplam;

  bool get kdvVarMi => kdvOrani > 0;

  @override
  bool operator ==(Object other) =>
      other is FaturaToplami &&
      other.araToplam == araToplam &&
      other.kdvOrani == kdvOrani &&
      other.kdv == kdv &&
      other.toplam == toplam;

  @override
  int get hashCode => Object.hash(araToplam, kdvOrani, kdv, toplam);

  @override
  String toString() =>
      'FaturaToplami(${araToplam.deger} + %$kdvOrani = ${toplam.deger})';
}
