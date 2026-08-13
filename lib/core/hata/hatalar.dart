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
/// Giriş Google hesabıyla yapılıyor; şifre diye bir şey yok. Bu yüzden
/// mesajlar kullanıcıya "şifreni düzelt" demez — ya bağlantı yoktur, ya hesap
/// kapatılmıştır, ya da derleme yanlış yapılandırılmıştır.
class KimlikHatasi extends UygulamaHatasi {
  const KimlikHatasi(super.mesaj);

  /// Google girişi yapılandırılmamış: `Info.plist` içindeki `GIDClientID` /
  /// URL şeması eksik ya da Firebase Console'da Google sağlayıcısı kapalı.
  const KimlikHatasi.yapilandirilmamis()
    : super(
        'Uygulama eksik kurulmuş: Google girişi yapılandırılmamış. '
        'Uygulamayı kuran kişiye bildirin.',
      );

  /// Giriş akışı yarıda kaldı. Beklenmez; yine de sessiz kalmaktansa
  /// anlaşılır bir mesaj gösterilir.
  const KimlikHatasi.acilamadi()
    : super('Giriş yapılamadı. Lütfen tekrar deneyin.');

  /// Firebase Auth hata kodunu Türkçe mesaja çevirir.
  factory KimlikHatasi.koddan(String kod) => KimlikHatasi(switch (kod) {
    'network-request-failed' =>
      'İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin.',
    'too-many-requests' =>
      'Çok fazla deneme yapıldı. Bir süre sonra tekrar deneyin.',
    'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
    // Aşağıdakiler kullanıcı hatası değil, yapılandırma hatasıdır: Firebase
    // Console'da Google sağlayıcısı kapalı ya da istemci kimliği yanlış.
    'operation-not-allowed' ||
    'invalid-credential' ||
    'account-exists-with-different-credential' =>
      'Google girişi bu projede etkin değil. Uygulamayı kuran kişiye bildirin.',
    _ => 'Giriş yapılamadı. Lütfen tekrar deneyin.',
  });
}

/// Oturum açık ama hesap izin listesinde değil.
///
/// İzin `firestore.rules` içindeki `izinliler` koleksiyonundan geliyor; listeye
/// e-posta eklemek konsoldan yapılan bir iş, kullanıcının uygulama içinde
/// düzeltebileceği bir şey değil.
///
/// Ayrı bir tip olmasının sebebi: yönlendirici ve giriş ekranı bu durumu
/// "veriler yüklenemedi"den ayırt edip kullanıcıyı çıkış düğmesine
/// yönlendirmeli. Mesaja bakarak ayırmak kırılgan olurdu.
class YetkiHatasi extends UygulamaHatasi {
  const YetkiHatasi()
      : super('Bu hesabın deftere erişim izni yok. Uygulamayı kuran kişiden '
            'e-posta adresinizi izin listesine eklemesini isteyin.');
}

/// Veri okuma/yazma hatası.
class VeriHatasi extends UygulamaHatasi {
  const VeriHatasi(super.mesaj);

  const VeriHatasi.yazilamadi() : super('Kayıt yapılamadı. Tekrar deneyin.');

  const VeriHatasi.okunamadi() : super('Veriler yüklenemedi. Tekrar deneyin.');

  /// Repository sağlayıcısı oturum açılmadan kurulmuş. Kullanıcı hatası değil,
  /// programlama hatasıdır: yönlendirici o ana kadar açılış ekranında bekletir.
  const VeriHatasi.oturumYok() : super('Oturum açık değil.');

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
