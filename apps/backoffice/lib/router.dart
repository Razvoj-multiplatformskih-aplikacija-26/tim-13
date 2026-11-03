import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/profile_screen.dart';
import 'screens/work_orders_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/orders',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/orders'),
      GoRoute(
        path: '/orders',
        builder: (context, state) {
          final selected = state.uri.queryParameters['selected'];
          return WorkOrdersScreen(selectedId: selected == null ? null : WorkOrderId(selected));
        },
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    ],
  );
}
