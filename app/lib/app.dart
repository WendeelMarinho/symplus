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
import 'core/design/app_colors.dart';
import 'core/design/app_typography.dart';
import 'core/design/app_spacing.dart';
import 'core/design/app_borders.dart';
import 'core/design/app_shadows.dart';

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
        // Color Scheme baseado no verde-neon SymplusTech
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onBackground, // Texto preto sobre verde neon
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: AppColors.onBackground,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.secondaryLight,
          onSecondaryContainer: Colors.white,
          tertiary: AppColors.income,
          onTertiary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          background: AppColors.background,
          onBackground: AppColors.onBackground,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          surfaceVariant: AppColors.scaffoldBackground,
          onSurfaceVariant: AppColors.textSecondary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        // AppBar
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          titleTextStyle: AppTypography.display.copyWith(fontSize: 24),
        ),
        // Cards
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.cardRadius),
            side: BorderSide(color: AppColors.border, width: AppBorders.borderWidth),
          ),
          color: AppColors.surface,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
        ),
        // FAB
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
          ),
        ),
        // Buttons
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            textStyle: AppTypography.button,
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: AppBorders.borderWidth),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorders.buttonRadius),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            textStyle: AppTypography.button,
          ),
        ),
        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorders.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorders.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorders.inputRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorders.inputRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        // Chips
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          labelStyle: AppTypography.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.chipRadius),
            side: const BorderSide(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
        ),
        // Typography
        typography: Typography.material2021(),
        textTheme: TextTheme(
          displayLarge: AppTypography.display.copyWith(fontSize: 32),
          displayMedium: AppTypography.display.copyWith(fontSize: 28),
          displaySmall: AppTypography.display.copyWith(fontSize: 24),
          headlineLarge: AppTypography.sectionTitle.copyWith(fontSize: 22),
          headlineMedium: AppTypography.sectionTitle.copyWith(fontSize: 20),
          headlineSmall: AppTypography.sectionTitle.copyWith(fontSize: 18),
          titleLarge: AppTypography.cardTitle.copyWith(fontSize: 16),
          titleMedium: AppTypography.cardTitle.copyWith(fontSize: 14),
          titleSmall: AppTypography.label,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.caption,
          labelLarge: AppTypography.button,
          labelMedium: AppTypography.label,
          labelSmall: AppTypography.caption,
        ),
        // Dividers
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
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

