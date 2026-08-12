import 'cari_kaydi.dart';

/// Cari listesinin tek bir sayfası.
///
/// Koleksiyonun tamamı hiçbir zaman tek `get()` ile çekilmez; Firestore okuma
/// başına ücretlendirir ve 500 carili bir listede her açılış 500 okuma demektir
/// (bkz. KURALLAR.md §4.3).
class CariSayfasi {
  const CariSayfasi({required this.kayitlar, required this.dahaVar});

  static const CariSayfasi bos = CariSayfasi(
    kayitlar: <CariKaydi>[],
    dahaVar: false,
  );

  final List<CariKaydi> kayitlar;

  /// Sunucuda okunacak kayıt kaldı mı. İstenen sayfa boyu kadar kayıt geldiyse
  /// devamı olduğu varsayılır.
  final bool dahaVar;
}
