import 'islem_kaydi.dart';

/// Bir sayfalık işlem listesi.
///
/// Firestore okuma başına ücretlendirir; işlem listesi tek seferde çekilmez
/// (bkz. KURALLAR.md §4.3).
class IslemSayfasi {
  const IslemSayfasi({required this.kayitlar, required this.dahaVar});

  static const IslemSayfasi bos = IslemSayfasi(
    kayitlar: <IslemKaydi>[],
    dahaVar: false,
  );

  /// En yeniden en eskiye sıralı kayıtlar.
  final List<IslemKaydi> kayitlar;

  /// Okunacak daha eski kayıt var mı? Sorgunun sınırı kadar kayıt geldiyse
  /// devamı olduğu varsayılır.
  final bool dahaVar;
}
