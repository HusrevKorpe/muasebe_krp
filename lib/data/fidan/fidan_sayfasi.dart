import 'fidan_kaydi.dart';

/// Fidan katalogunun tek bir sayfası.
///
/// Katalog da cari listesi gibi sayfalanır: koleksiyonun tamamı tek `get()` ile
/// çekilmez, Firestore okuma başına ücretlendirir (bkz. KURALLAR.md §4.3).
class FidanSayfasi {
  const FidanSayfasi({required this.kayitlar, required this.dahaVar});

  static const FidanSayfasi bos = FidanSayfasi(
    kayitlar: <FidanKaydi>[],
    dahaVar: false,
  );

  final List<FidanKaydi> kayitlar;

  /// Sunucuda okunacak kayıt kaldı mı. İstenen sayfa boyu kadar kayıt geldiyse
  /// devamı olduğu varsayılır.
  final bool dahaVar;
}
