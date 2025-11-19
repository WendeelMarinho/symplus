import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/navigation/app_shell.dart';
import '../core/navigation/menu_catalog.dart';
import '../core/widgets/toast_service.dart';
import '../core/auth/auth_provider.dart';
import '../core/rbac/permission_helper.dart';
import '../features/accounts/presentation/pages/accounts_page.dart';
import '../features/accounts/presentation/pages/account_detail_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/categories/presentation/pages/categories_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/dashboard/presentation/pages/dashboard_details_page.dart';
import '../features/custom_indicators/presentation/pages/custom_indicator_details_page.dart';
import '../features/documents/presentation/pages/documents_page.dart';
import '../features/due_items/presentation/pages/due_items_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/reports/presentation/pages/reports_page.dart';
import '../features/requests/presentation/pages/requests_page.dart';
import '../features/requests/presentation/pages/request_detail_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/subscription/presentation/pages/subscription_page.dart';
import '../features/transactions/presentation/pages/transactions_page.dart';
import '../features/transactions/presentation/pages/transaction_detail_page.dart';
import '../features/overview/presentation/pages/overview_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplashRoute = state.matchedLocation == '/splash';
      final isAppRoute = state.matchedLocation.startsWith('/app');

      // Se não está autenticado e tenta acessar rotas protegidas
      if (!isAuthenticated && isAppRoute) {
        return '/login';
      }

      // Se está autenticado e tenta acessar login/splash
      if (isAuthenticated && (isLoginRoute || isSplashRoute)) {
        return '/app/dashboard';
      }

      // Verificar RBAC para rotas protegidas usando permissões
      if (isAuthenticated && isAppRoute) {
        final route = state.matchedLocation;
        final menuItem = MenuCatalog.getItemByRoute(route);
        
        if (menuItem != null && menuItem.requiredPermission != null) {
          final hasPermission = MenuCatalog.isRouteAllowed(route, authState.role);
          if (!hasPermission) {
            // Redirecionar para dashboard se não tem permissão e sinalizar motivo com rota negada
            final deniedRoute = route.replaceAll('/app/', '');
            // Log de telemetria
            PermissionHelper.logRedirect(authState, route, menuItem.requiredPermission);
            return '/app/dashboard?denied=1&route=$deniedRoute';
          }
        } else if (menuItem != null && !authState.isRouteAllowed(route)) {
          // Fallback para allowedRoles
          final deniedRoute = route.replaceAll('/app/', '');
          return '/app/dashboard?denied=1&route=$deniedRoute';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // Rotas protegidas dentro do Shell
      GoRoute(
        path: '/app',
        redirect: (context, state) => '/app/dashboard',
      ),
      GoRoute(
        path: '/app/overview',
        name: 'overview',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.overview,
            child: const OverviewPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          // Exibir toast de acesso negado quando redirecionado por RBAC
          final denied = state.uri.queryParameters['denied'] == '1';
          final deniedRoute = state.uri.queryParameters['route'] ?? '';
          if (denied) {
            // Usar um microtask para garantir que o contexto esteja montado
            Future.microtask(() {
              if (context.mounted) {
                final message = deniedRoute.isNotEmpty
                    ? 'Acesso negado: você não tem permissão para acessar "$deniedRoute"'
                    : 'Acesso negado: você não tem permissão para esta página';
                ToastService.showWarning(context, message);
              }
            });
          }
          return AppShell(
            currentRoute: MenuCatalog.dashboard,
            child: const DashboardPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/dashboard/details/:type',
        name: 'dashboard-details',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'income';
          return AppShell(
            currentRoute: MenuCatalog.dashboard,
            child: DashboardDetailsPage(type: type),
          );
        },
      ),
      GoRoute(
        path: '/app/custom-indicators/:id',
        name: 'custom-indicator-details',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AppShell(
            currentRoute: MenuCatalog.dashboard,
            child: CustomIndicatorDetailsPage(indicatorId: id),
          );
        },
      ),
      GoRoute(
        path: '/app/accounts',
        name: 'accounts',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.accounts,
            child: const AccountsPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/accounts/:id',
        name: 'account-detail',
        builder: (context, state) {
          final accountId = int.parse(state.pathParameters['id']!);
          return AppShell(
            currentRoute: MenuCatalog.accounts,
            child: AccountDetailPage(accountId: accountId),
          );
        },
      ),
      GoRoute(
        path: '/app/transactions',
        name: 'transactions',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.transactions,
            child: const TransactionsPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/transactions/:id',
        name: 'transaction-detail',
        builder: (context, state) {
          final transactionId = int.parse(state.pathParameters['id']!);
          return AppShell(
            currentRoute: MenuCatalog.transactions,
            child: TransactionDetailPage(transactionId: transactionId),
          );
        },
      ),
      GoRoute(
        path: '/app/categories',
        name: 'categories',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.categories,
            child: const CategoriesPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/due-items',
        name: 'due-items',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.dueItems,
            child: const DueItemsPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/documents',
        name: 'documents',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.documents,
            child: const DocumentsPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/requests',
        name: 'requests',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.requests,
            child: const RequestsPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/requests/:id',
        name: 'request-detail',
        builder: (context, state) {
          final ticketId = int.parse(state.pathParameters['id']!);
          return AppShell(
            currentRoute: MenuCatalog.requests,
            child: RequestDetailPage(ticketId: ticketId),
          );
        },
      ),
      GoRoute(
        path: '/app/notifications',
        name: 'notifications',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.notifications,
            child: const NotificationsPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/subscription',
        name: 'subscription',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.subscription,
            child: const SubscriptionPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/reports/pl',
        name: 'reports-pl',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.reportsPl,
            child: const ReportsPage(),
          );
        },
      ),
      GoRoute(
        path: '/app/profile',
        name: 'profile',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.profile,
            child: const ProfilePage(),
          );
        },
      ),
      GoRoute(
        path: '/app/settings',
        name: 'settings',
        builder: (context, state) {
          return AppShell(
            currentRoute: MenuCatalog.settings,
            child: const SettingsPage(),
          );
        },
      ),
    ],
  );
});

