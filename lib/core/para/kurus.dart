/// Parasal değer. Değeri **her zaman kuruş cinsinden tam sayı** olarak tutar.
///
/// Muhasebe hesabında ondalıklı sayı kullanmak kaçınılmaz olarak sapma üretir
/// (`0.1 + 0.2 == 0.30000000000000004`). Dört yıllık bir ekstrede binlerce toplama
/// yapılınca bu sapma kuruştan liraya çıkar ve müşteriye yanlış borç gösterilir.
///
/// Bu tip, para değerlerinin hiçbir aşamada `double`'a düşmemesini tip düzeyinde
/// garanti eder. Bkz. KURALLAR.md §3.1.
class Kurus implements Comparable<Kurus> {
  /// [deger] kuruş cinsindendir: `94.000,00 ₺` için `9400000`.
  const Kurus(this.deger);

  /// Lira ve kuruş parçalarından oluşturur: `Kurus.liradan(94000)` → `94.000,00 ₺`.
  factory Kurus.liradan(int lira, [int kurus = 0]) {
    if (kurus < 0 || kurus > 99) {
      throw ArgumentError.value(kurus, 'kurus', 'Kuruş 0-99 aralığında olmalı');
    }
    return Kurus(lira < 0 ? lira * 100 - kurus : lira * 100 + kurus);
  }

  static const Kurus sifir = Kurus(0);

  final int deger;

  /// Tam lira kısmı, işaretsiz. `-12.031,25 ₺` → `12031`
  int get liraKismi => deger.abs() ~/ 100;

  /// Kuruş kısmı, işaretsiz. `-12.031,25 ₺` → `25`
  int get kurusKismi => deger.abs() % 100;

  bool get sifirMi => deger == 0;
  bool get negatifMi => deger < 0;
  bool get pozitifMi => deger > 0;

  Kurus get mutlak => Kurus(deger.abs());

  Kurus operator +(Kurus other) => Kurus(deger + other.deger);
  Kurus operator -(Kurus other) => Kurus(deger - other.deger);
  Kurus operator -() => Kurus(-deger);

  /// Tam sayı katsayıyla çarpar. Miktar × birim fiyat için kullanılır.
  Kurus operator *(int katsayi) => Kurus(deger * katsayi);

  bool operator <(Kurus other) => deger < other.deger;
  bool operator <=(Kurus other) => deger <= other.deger;
  bool operator >(Kurus other) => deger > other.deger;
  bool operator >=(Kurus other) => deger >= other.deger;

  @override
  int compareTo(Kurus other) => deger.compareTo(other.deger);

  @override
  bool operator ==(Object other) => other is Kurus && other.deger == deger;

  @override
  int get hashCode => deger.hashCode;

  @override
  String toString() => 'Kurus($deger)';
}

/// [Kurus] listesini toplar. Boş listede [Kurus.sifir] döner.
Kurus kurusTopla(Iterable<Kurus> tutarlar) =>
    tutarlar.fold(Kurus.sifir, (toplam, tutar) => toplam + tutar);
