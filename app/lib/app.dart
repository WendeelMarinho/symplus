import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/router.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/auth/auth_session_handler.dart';
import 'core/auth/auth_provider.dart';
import 'core/widgets/toast_service.dart';

class SymplusApp extends ConsumerWidget {
  const SymplusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final localeState = ref.watch(localeProvider);

    // Configurar handler de sessão para tratar 401
    AuthSessionHandler.configure(
      onTokenExpired: () async {
        // Resetar auth provider
        ref.read(authProvider.notifier).logout();
        
        // Redirecionar para login com parâmetro indicando expiração
        router.go('/login?expired=1');
      },
    );

    return MaterialApp.router(
      title: 'Symplus Finance',
      debugShowCheckedModeBanner: false,
      locale: localeState.flutterLocale,
      supportedLocales: const [
        Locale('pt', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo, // Brand roxo/indigo
          brightness: Brightness.light,
        ).copyWith(
          // Tokens de cor customizados
          primary: Colors.indigo.shade700,
          secondary: Colors.purple.shade600,
          // Green para receitas
          tertiary: Colors.green.shade600,
          // Red para despesas
          error: Colors.red.shade600,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        // Cards com radius médio e sombras suaves
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // FAB theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Configurações de responsividade
        typography: Typography.material2021(),
        textTheme: const TextTheme(
          // Títulos responsivos
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        ),
      ),
      // Configurações de acessibilidade
      builder: (context, child) {
        return MediaQuery(
          // Garantir tamanho mínimo de fonte para acessibilidade
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.5,
            ),
          ),
          child: child!,
        );
      },
      routerConfig: router,
    );
  }
}

