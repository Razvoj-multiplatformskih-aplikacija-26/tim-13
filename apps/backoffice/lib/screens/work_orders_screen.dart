import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../data/fake_work_orders.dart';
import '../dependencies.dart';
import '../shortcuts.dart';
import '../widgets/new_work_order_dialog.dart';
import '../widgets/order_detail_panel.dart';
import '../widgets/order_rows.dart';

enum _DemoAction { reload, failure, empty }

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key, this.selectedId});

  final WorkOrderId? selectedId;

  static String pathFor(WorkOrderId? selected) => selected == null ? '/orders' : '/orders?selected=${selected.value}';

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  final _rowsFocus = FocusNode(debugLabel: 'work order rows');

  WorkOrdersBoardBloc get _bloc => context.read<WorkOrdersBoardBloc>();

  @override
  void initState() {
    super.initState();
    _syncWithRoute();
  }

  @override
  void didUpdateWidget(WorkOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _syncWithRoute();
  }

  @override
  void dispose() {
    _rowsFocus.dispose();
    super.dispose();
  }

  void _syncWithRoute() {
    final state = _bloc.state;
    if (state is BoardLoaded && state.selectedId != widget.selectedId) _bloc.add(BoardOrderSelected(widget.selectedId));
  }

  WorkOrder? get _selected => switch (_bloc.state) {
    BoardLoaded(:final selected) => selected,
    _ => null,
  };

  bool _allows(WorkOrderAction action) {
    final state = _bloc.state;
    final selected = _selected;
    return state is BoardLoaded && !state.isBusy && selected != null && state.actionsFor(selected).contains(action);
  }

  void _approve() {
    final selected = _selected;
    if (selected != null) _bloc.add(BoardApprovalRequested(selected.id));
  }

  Future<void> _reject() async {
    final selected = _selected;
    if (selected == null) return;
    final reason = await showReasonDialog(context, title: 'Odbiti izveštaj?', confirmLabel: 'Odbij izveštaj');
    if (mounted && reason != null) _bloc.add(BoardRejectionRequested(selected.id, reason: reason));
  }

  Future<void> _cancel() async {
    final selected = _selected;
    if (selected == null) return;
    final reason = await showReasonDialog(
      context,
      title: 'Otkazati nalog?',
      confirmLabel: 'Otkaži nalog',
      description: 'Otkazan nalog ne može da se vrati.',
    );
    if (mounted && reason != null) _bloc.add(BoardCancellationRequested(selected.id, reason: reason));
  }

  Future<void> _newOrder() async {
    final state = _bloc.state;
    if (state is! BoardLoaded) return;
    final dependencies = context.read<BackofficeDependencies>();
    final created = await showNewWorkOrderDialog(context, book: state.book, dependencies: dependencies);
    if (!mounted || created == null) return;
    _bloc.add(const BoardRefreshed());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Radni nalog je sačuvan.')));
  }

  void _onDemoAction(_DemoAction action, FakeWorkOrders fake) {
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _DemoAction.reload:
        _bloc.add(const BoardRequested());
      case _DemoAction.failure:
        fake.failingRequests = 1;
        messenger.showSnackBar(const SnackBar(content: Text('Sledeći zahtev neće uspeti.')));
      case _DemoAction.empty:
        fake.emptyResponses = 1;
        messenger.showSnackBar(const SnackBar(content: Text('Sledeći odgovor će biti prazan.')));
    }
  }

  void _showNotice(BuildContext context, BoardNotice notice) {
    final message = switch (notice) {
      BoardActionSucceeded(:final order) => switch (order.status) {
        Completed() => 'Nalog je odobren.',
        Rejected() => 'Nalog je vraćen na doradu.',
        Cancelled() => 'Nalog je otkazan.',
        Planned() || InProgress() || AwaitingConfirmation() => 'Nalog je sačuvan.',
      },
      BoardActionRejected(:final error) => error.message,
      BoardActionFailed() => 'Izmena nije sačuvana.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _bloc.add(const BoardNoticeAcknowledged());
  }

  KeyEventResult _onRowsKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _bloc.add(const BoardCursorMoved(1));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _bloc.add(const BoardCursorMoved(-1));
    } else if (key == LogicalKeyboardKey.enter && event is KeyDownEvent) {
      _bloc.add(const BoardCursorActivated());
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final fake = context.read<BackofficeDependencies>().fakeOrders;
    return Shortcuts(
      shortcuts: boardShortcuts,
      child: Actions(
        actions: {
          ApproveIntent: GuardedCallbackAction<ApproveIntent>(
            enabled: () => _allows(WorkOrderAction.approve),
            onInvoke: (_) => _approve(),
          ),
          RejectIntent: GuardedCallbackAction<RejectIntent>(
            enabled: () => _allows(WorkOrderAction.reject),
            onInvoke: (_) => _reject(),
          ),
          CancelIntent: GuardedCallbackAction<CancelIntent>(
            enabled: () => _allows(WorkOrderAction.cancel),
            onInvoke: (_) => _cancel(),
          ),
          NewOrderIntent: CallbackAction<NewOrderIntent>(onInvoke: (_) => _newOrder()),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) {
              _bloc.add(const BoardOrderSelected(null));
              _rowsFocus.requestFocus();
              return null;
            },
          ),
          ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(onInvoke: (_) => showShortcutsOverview(context)),
        },
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              spacing: 10,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.eco, size: 20, color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
                const Text('AgroFlow'),
                Flexible(
                  child: Text(
                    'Backoffice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(tooltip: 'Novi nalog (N)', onPressed: _newOrder, icon: const Icon(Icons.add)),
              IconButton(
                tooltip: 'Prečice (?)',
                onPressed: () => showShortcutsOverview(context),
                icon: const Icon(Icons.keyboard_outlined),
              ),
              if (fake != null)
                PopupMenuButton<_DemoAction>(
                  tooltip: 'Simulacija',
                  onSelected: (action) => _onDemoAction(action, fake),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: _DemoAction.reload, child: Text('Učitaj ponovo')),
                    PopupMenuItem(value: _DemoAction.failure, child: Text('Simuliraj grešku')),
                    PopupMenuItem(value: _DemoAction.empty, child: Text('Simuliraj prazan odgovor')),
                  ],
                ),
              IconButton(
                tooltip: 'Profil',
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
              const SizedBox(width: 48),
            ],
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<WorkOrdersBoardBloc, WorkOrdersBoardState>(
                listenWhen: (previous, current) => previous is! BoardLoaded && current is BoardLoaded,
                listener: (context, state) => _syncWithRoute(),
              ),
              BlocListener<WorkOrdersBoardBloc, WorkOrdersBoardState>(
                listenWhen: (previous, current) =>
                    previous is BoardLoaded && current is BoardLoaded && previous.selectedId != current.selectedId,
                listener: (context, state) {
                  final selectedId = (state as BoardLoaded).selectedId;
                  if (selectedId != widget.selectedId) context.go(WorkOrdersScreen.pathFor(selectedId));
                },
              ),
            ],
            child: Focus(
              focusNode: _rowsFocus,
              autofocus: true,
              onKeyEvent: _onRowsKey,
              child: BlocConsumer<WorkOrdersBoardBloc, WorkOrdersBoardState>(
                listenWhen: (previous, current) => current is BoardLoaded && current.notice != null,
                listener: (context, state) => _showNotice(context, (state as BoardLoaded).notice!),
                builder: (context, state) => switch (state) {
                  BoardLoading() => const LoadingView(),
                  BoardFailure() => FailureView(onRetry: () => _bloc.add(const BoardRequested())),
                  BoardEmpty() => const EmptyView(title: 'Nema radnih naloga.'),
                  BoardLoaded() => _LoadedBody(
                    state: state,
                    focus: _rowsFocus,
                    onApprove: _approve,
                    onReject: _reject,
                    onCancel: _cancel,
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.focus,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  final BoardLoaded state;
  final FocusNode focus;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<WorkOrdersBoardBloc>();
    final selected = state.selected;

    Widget rows({required bool wide}) => ListenableBuilder(
      listenable: focus,
      builder: (context, _) => OrderRows(
        key: ValueKey(wide),
        wide: wide,
        book: state.book,
        orders: state.visible,
        cursor: state.cursor,
        selectedId: state.selectedId,
        hasFocus: focus.hasFocus,
        onSelect: (order) {
          focus.requestFocus();
          bloc.add(BoardOrderSelected(order.id));
        },
      ),
    );

    Widget? detail() => selected == null
        ? null
        : OrderDetailPanel(
            order: selected,
            book: state.book,
            actions: state.actionsFor(selected),
            busy: state.isBusy,
            onApprove: onApprove,
            onReject: onReject,
            onCancel: onCancel,
            onClose: () {
              bloc.add(const BoardOrderSelected(null));
              focus.requestFocus();
            },
          );

    return Column(
      children: [
        _StageFilter(selected: state.filter),
        SizedBox(height: 3, child: state.isBusy ? const LinearProgressIndicator() : null),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panel = detail();
              if (constraints.maxWidth >= Breakpoints.wide) {
                return Row(
                  children: [
                    Expanded(child: rows(wide: true)),
                    if (panel != null) ...[const VerticalDivider(width: 1), SizedBox(width: 340, child: panel)],
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: rows(wide: false)),
                  if (panel != null) ...[
                    const Divider(height: 1),
                    SizedBox(height: constraints.maxHeight * 0.5, child: panel),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StageFilter extends StatelessWidget {
  const _StageFilter({required this.selected});

  final WorkOrderStage? selected;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<WorkOrdersBoardBloc>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Svi'),
            selected: selected == null,
            onSelected: (_) => bloc.add(const BoardFilterChanged(null)),
          ),
          for (final stage in WorkOrderStage.values)
            ChoiceChip(
              label: Text(stage.label),
              selected: selected == stage,
              onSelected: (_) => bloc.add(BoardFilterChanged(stage)),
            ),
        ],
      ),
    );
  }
}
