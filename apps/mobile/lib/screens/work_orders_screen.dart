import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../data/fake_work_orders.dart';
import '../dependencies.dart';
import '../widgets/work_order_card.dart';

enum _DemoAction { reload, failure, empty }

class WorkOrdersScreen extends StatelessWidget {
  const WorkOrdersScreen.active({super.key})
    : title = 'Zaduženja',
      emptyTitle = 'Nema aktivnih naloga.',
      history = false;

  const WorkOrdersScreen.history({super.key}) : title = 'Istorija', emptyTitle = 'Istorija je prazna.', history = true;

  final String title;
  final String emptyTitle;
  final bool history;

  void _onDemoAction(BuildContext context, _DemoAction action, FakeWorkOrders fake) {
    switch (action) {
      case _DemoAction.reload:
        context.read<MyWorkOrdersBloc>().add(const MyWorkOrdersRequested());
      case _DemoAction.failure:
        fake.failingRequests = 1;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sledeći zahtev neće uspeti.')));
      case _DemoAction.empty:
        fake.emptyResponses = 1;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sledeći odgovor će biti prazan.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyWorkOrdersBloc>();
    final fake = context.read<AppDependencies>().fakeOrders;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (fake != null)
            PopupMenuButton<_DemoAction>(
              tooltip: 'Simulacija',
              onSelected: (action) => _onDemoAction(context, action, fake),
              itemBuilder: (context) => const [
                PopupMenuItem(value: _DemoAction.reload, child: Text('Učitaj ponovo')),
                PopupMenuItem(value: _DemoAction.failure, child: Text('Simuliraj grešku')),
                PopupMenuItem(value: _DemoAction.empty, child: Text('Simuliraj prazan odgovor')),
              ],
            ),
        ],
      ),
      body: BlocBuilder<MyWorkOrdersBloc, MyWorkOrdersState>(
        builder: (context, state) => switch (state) {
          MyWorkOrdersLoading() => const LoadingView(),
          MyWorkOrdersFailure() => FailureView(onRetry: () => bloc.add(const MyWorkOrdersRequested())),
          MyWorkOrdersEmpty() => const EmptyView(title: 'Nemate dodeljenih naloga.'),
          MyWorkOrdersLoaded() => _OrderList(
            orders: history ? state.history : state.active,
            emptyTitle: emptyTitle,
            state: state,
          ),
        },
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.emptyTitle, required this.state});

  final List<WorkOrder> orders;
  final String emptyTitle;
  final MyWorkOrdersLoaded state;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return EmptyView(title: emptyTitle);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return WorkOrderCard(
          key: ValueKey(order.id),
          order: order,
          parcel: state.book.parcelOf(order),
          onOpen: () => context.push('/orders/${order.id.value}'),
        );
      },
    );
  }
}
