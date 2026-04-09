import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app/app_state.dart';
import 'features/splash/presentation/splash_page.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.load();

  runApp(RecollectoApp(appState: appState));
}

class RecollectoApp extends StatelessWidget {
  final AppState appState;

  const RecollectoApp({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return _AppStateScope(
          appState: appState,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Recollecto',
            locale: appState.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: appState.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: const Color(0xFF8B6F7D),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: const Color(0xFF8B6F7D),
            ),
            home: const SplashPage(),
          ),
        );
      },
    );
  }
}

class _AppStateScope extends InheritedWidget {
  final AppState appState;

  const _AppStateScope({
    required this.appState,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppStateScope>();
    assert(scope != null, 'No AppState found in context');
    return scope!.appState;
  }

  @override
  bool updateShouldNotify(_AppStateScope oldWidget) {
    return oldWidget.appState != appState;
  }
}

extension AppStateX on BuildContext {
  AppState get appState => _AppStateScope.of(this);
}
