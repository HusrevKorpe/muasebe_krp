import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/cari/cari_repository.dart';
import '../../../domain/cari/cari_suzgeci.dart';
import '../../ortak/viewmodel/saglayici_onbellegi.dart';

/// Süzgece uyan kişilerin tam sayısı — liste başındaki "128 kişi".
///
/// Liste sayfalı geldiği için sayı ekrandaki satırlardan çıkmıyor: sınır kadar
/// kayıt yüklüyken gerçek sayı daha büyük olabilir. Bu yüzden sunucuya ayrı bir
/// toplama sorgusu gidiyor (`CariRepository.sayiyiOku`).
///
/// Sağlayıcı yalnızca liste kesikken izleniyor (bkz. `CariListeGorunumu`):
/// sayfanın tamamı yüklüyse eldeki satırları saymak hem bedava hem kesin.
///
/// Kişi eklenip çıkarıldığında `CariFormViewModel` bu sağlayıcıyı düşürüyor;
/// sayı bir sonraki okumada yeniden sorulur. Ortak defterin öteki telefonundan
/// gelen kayıt ise en geç [birSureSakla] penceresi kapanınca ya da listeyi
/// aşağı çekince sayıya yansır — liste zaten canlı, arada kalan tek şey sayı.
final cariSayisiSaglayici = FutureProvider.family<int, CariSuzgeci>((
  ref,
  suzgec,
) {
  birSureSakla(ref);
  return ref.watch(cariRepositorySaglayici).sayiyiOku(suzgec: suzgec);
}, isAutoDispose: true);
