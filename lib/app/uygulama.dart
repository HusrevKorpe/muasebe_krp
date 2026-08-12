import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tema.dart';
import 'yonlendirici.dart';

class FidanCariUygulamasi extends ConsumerWidget {
  const FidanCariUygulamasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FidanCari',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(yonlendiriciSaglayici),
      theme: Tema.acik(),
      darkTheme: Tema.koyu(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
