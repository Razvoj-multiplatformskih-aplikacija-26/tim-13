import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dependencies.dart';
import 'screens/home_shell.dart';
import 'screens/profile_screen.dart';
import 'screens/work_order_detail_screen.dart';
import 'screens/work_orders_screen.dart';
import 'screens/work_report_screen.dart';

WorkOrder? _orderFor(BuildContext context, GoRouterState state) {
  final orders = context.read<MyWorkOrdersBloc>().state;
  if (orders is! MyWorkOrdersLoaded) return null;
  return orders.book.find(WorkOrderId(state.pathParameters['id']!));
}

GoRouter createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (context, state) => const WorkOrdersScreen.active())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/history', builder: (context, state) => const WorkOrdersScreen.history())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => WorkOrderDetailScreen(id: WorkOrderId(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'report',
            parentNavigatorKey: rootNavigatorKey,
            redirect: (context, state) => _orderFor(context, state) == null ? '/' : null,
            builder: (context, state) {
              final order = _orderFor(context, state)!;
              final orders = context.read<MyWorkOrdersBloc>().state as MyWorkOrdersLoaded;
              final dependencies = context.read<AppDependencies>();
              return BlocProvider(
                create: (_) => WorkReportFormBloc(
                  submitWorkReport: dependencies.submitWorkReport,
                  worker: dependencies.worker,
                  order: order,
                  remaining: orders.book.remainingFor(order) ?? Hectares.zero,
                ),
                child: WorkReportScreen(order: order, book: orders.book),
              );
            },
          ),
        ],
      ),
    ],
  );
}
