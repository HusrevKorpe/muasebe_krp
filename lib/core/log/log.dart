import 'dart:developer' as gelistirici;

import 'package:flutter/foundation.dart';

/// Uygulama günlüğü. `print` yerine bu kullanılır — bkz. KURALLAR.md §2.
///
/// Sürüm derlemesinde yalnızca hata kayıtları geçer; bilgi ve uyarı kayıtları
/// yayına çıkmaz.
abstract final class Log {
  static const String _kanal = 'FidanCari';

  static void bilgi(String mesaj) {
    if (kDebugMode) {
      gelistirici.log(mesaj, name: _kanal, level: 800);
    }
  }

  static void uyari(String mesaj) {
    if (kDebugMode) {
      gelistirici.log(mesaj, name: _kanal, level: 900);
    }
  }

  static void hata(String mesaj, [Object? sebep, StackTrace? yigin]) {
    gelistirici.log(
      mesaj,
      name: _kanal,
      level: 1000,
      error: sebep,
      stackTrace: yigin,
    );
  }
}
