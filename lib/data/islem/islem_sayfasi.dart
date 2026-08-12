import 'islem_kaydi.dart';

/// Bir sayfalık işlem listesi.
///
/// Firestore okuma başına ücretlendirir; işlem listesi tek `get()` ile çekilmez
/// (bkz. KURALLAR.md §4.3).
class IslemSayfasi {
  const IslemSayfasi({required this.kayitlar, required this.dahaVar});

  static const IslemSayfasi bos = IslemSayfasi(
    kayitlar: <IslemKaydi>[],
    dahaVar: false,
  );

  /// En yeniden en eskiye sıralı kayıtlar.
  final List<IslemKaydi> kayitlar;

  /// Sunucuda okunacak daha eski kayıt var mı?
  final bool dahaVar;
}
