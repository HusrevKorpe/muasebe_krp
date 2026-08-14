import 'urun_kaydi.dart';

/// Ürün listesinin tek bir sayfası.
///
/// Liste de cari listesi gibi sayfalanır: koleksiyonun tamamı tek seferde
/// çekilmez, Firestore okuma başına ücretlendirir (bkz. KURALLAR.md §4.3).
class UrunSayfasi {
  const UrunSayfasi({required this.kayitlar, required this.dahaVar});

  static const UrunSayfasi bos = UrunSayfasi(
    kayitlar: <UrunKaydi>[],
    dahaVar: false,
  );

  final List<UrunKaydi> kayitlar;

  /// Okunacak kayıt kaldı mı. Sorgunun sınırı kadar kayıt geldiyse devamı
  /// olduğu varsayılır.
  final bool dahaVar;
}
