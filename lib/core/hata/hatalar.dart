/// Uygulama içi hata tipleri.
///
/// Firebase'in İngilizce hata kodları kullanıcıya gösterilmez; repository
/// katmanında bu tiplere çevrilir ve ekranda [mesaj] gösterilir.
sealed class UygulamaHatasi implements Exception {
  const UygulamaHatasi(this.mesaj);

  /// Kullanıcıya gösterilecek Türkçe mesaj.
  final String mesaj;

  @override
  String toString() => '$runtimeType: $mesaj';
}

/// Oturum açma hatası.
///
/// Giriş e-posta ve şifreyle yapılıyor. Hesapları Firebase Console açtığı için
/// "kayıt olun" gibi bir yönlendirme yok: yanlış bilgi girildiyse kullanıcı
/// ya tekrar dener ya da hesabı veren kişiye sorar.
class KimlikHatasi extends UygulamaHatasi {
  const KimlikHatasi(super.mesaj);

  /// Firebase Auth hata kodunu Türkçe mesaja çevirir.
  factory KimlikHatasi.koddan(String kod) => KimlikHatasi(switch (kod) {
    // Firebase, hesap var mı yok mu bilgisini sızdırmamak için yanlış şifre ile
    // olmayan hesabı aynı kodla ('invalid-credential') döner; eski sürümler
    // ayrı kodlar veriyordu. Mesaj her hâlde aynı olduğu için hepsi bir arada.
    'invalid-credential' ||
    'invalid-email' ||
    'wrong-password' ||
    'user-not-found' =>
      'E-posta veya şifre hatalı.',
    'network-request-failed' =>
      'İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin.',
    'too-many-requests' =>
      'Çok fazla deneme yapıldı. Bir süre sonra tekrar deneyin.',
    'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
    // Kullanıcı hatası değil, yapılandırma hatası: Firebase Console →
    // Authentication → Sign-in method altında Email/Password kapalı.
    'operation-not-allowed' =>
      'E-posta ile giriş bu projede kapalı. Uygulamayı kuran kişiye bildirin.',
    _ => 'Giriş yapılamadı. Lütfen tekrar deneyin.',
  });
}

/// Veri okuma/yazma hatası.
class VeriHatasi extends UygulamaHatasi {
  const VeriHatasi(super.mesaj);

  const VeriHatasi.yazilamadi() : super('Kayıt yapılamadı. Tekrar deneyin.');

  const VeriHatasi.okunamadi() : super('Veriler yüklenemedi. Tekrar deneyin.');

  /// Repository sağlayıcısı oturum açılmadan kurulmuş. Kullanıcı hatası değil,
  /// programlama hatasıdır: yönlendirici o ana kadar açılış ekranında bekletir.
  const VeriHatasi.oturumYok() : super('Oturum açık değil.');

  /// Firestore `permission-denied` döndü: oturum açık ama kurallar okumayı
  /// reddediyor.
  ///
  /// [oturumYok] ile karıştırılmamalı — bir kez karıştırıldı ve tanı saatler
  /// aldı. Oturum kapalıyken kullanıcı zaten giriş ekranındadır, veri ekranına
  /// hiç ulaşamaz; bu ekranda "oturum yok" yazıyorsa sebep oturum değil,
  /// kuraldır. Tipik nedeni `firestore.rules` dosyasının değişip canlıya
  /// yayınlanmamış olması (`firebase deploy --only firestore:rules`).
  const VeriHatasi.erisimReddedildi()
    : super('Bu hesabın deftere erişimi yok. Uygulamayı kuran kişiye bildirin.');

  /// Ekstre, açılış bakiyesi için aralıktan önceki tüm işlemleri okumak
  /// zorundadır ve sayfalanamaz. Okuma sınırı aşılırsa eksik veriyle ekstre
  /// üretmek yerine kullanıcıdan aralığı daraltması istenir — yanlış bakiye
  /// göstermek, ekstre üretememekten kötüdür.
  const VeriHatasi.cokFazlaIslem()
      : super('Bu cari için çok fazla işlem var. Daha dar bir tarih aralığı '
            'seçin.');
}

/// Girdi doğrulama hatası — form alanları için.
class DogrulamaHatasi extends UygulamaHatasi {
  const DogrulamaHatasi(super.mesaj);
}
