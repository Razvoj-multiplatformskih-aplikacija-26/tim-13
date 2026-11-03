import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

class OrderRows extends StatefulWidget {
  const OrderRows({
    super.key,
    required this.wide,
    required this.book,
    required this.orders,
    required this.cursor,
    required this.selectedId,
    required this.hasFocus,
    required this.onSelect,
  });

  final bool wide;
  final WorkBook book;
  final List<WorkOrder> orders;
  final int cursor;
  final WorkOrderId? selectedId;
  final bool hasFocus;
  final ValueChanged<WorkOrder> onSelect;

  @override
  State<OrderRows> createState() => _OrderRowsState();
}

class _OrderRowsState extends State<OrderRows> {
  final _scroll = ScrollController();

  double get _extent => widget.wide ? 56 : 76;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: false));
  }

  @override
  void didUpdateWidget(OrderRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cursor != widget.cursor) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: true));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _reveal({required bool animate}) {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final top = widget.cursor * _extent;
    final bottom = top + _extent;
    final double target;
    if (top < position.pixels) {
      target = top;
    } else if (bottom > position.pixels + position.viewportDimension) {
      target = bottom - position.viewportDimension;
    } else {
      return;
    }
    final offset = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(offset, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.orders.isEmpty) return const EmptyView(title: 'Nema naloga za izabrani filter.');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AgroTheme.radius,
        border: Border.all(
          color: widget.hasFocus ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: widget.hasFocus ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (widget.wide) const _Header(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemExtent: _extent,
              itemCount: widget.orders.length,
              itemBuilder: (context, index) {
                final order = widget.orders[index];
                return _Row(
                  key: ValueKey(order.id),
                  wide: widget.wide,
                  order: order,
                  book: widget.book,
                  selected: order.id == widget.selectedId,
                  cursor: widget.hasFocus && index == widget.cursor,
                  onTap: () => widget.onSelect(order),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _flexes = (parcel: 3, operation: 3, worker: 3, machine: 4, interval: 4, status: 4);

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text, style: style),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          cell('Parcela', _flexes.parcel),
          cell('Mera', _flexes.operation),
          cell('Radnik', _flexes.worker),
          cell('Mašina', _flexes.machine),
          cell('Termin', _flexes.interval),
          cell('Stanje', _flexes.status),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.wide,
    required this.order,
    required this.book,
    required this.selected,
    required this.cursor,
    required this.onTap,
  });

  final bool wide;
  final WorkOrder order;
  final WorkBook book;
  final bool selected;
  final bool cursor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parcel = book.parcelOf(order)?.name ?? '—';
    final worker = book.workerOf(order)?.name ?? '—';
    final stage = order.status.stage;

    Widget cell(String text, int flex, {TextStyle? style}) => Expanded(
      flex: flex,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '$parcel, ${order.operation.label}, $worker, ${stage.label}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: cursor
                  ? Border.all(color: scheme.primary, width: 2)
                  : Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: wide
                ? Row(
                    children: [
                      cell(parcel, _flexes.parcel, style: theme.textTheme.titleSmall),
                      Expanded(
                        flex: _flexes.operation,
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(order.operation.icon, size: 18, color: stage.colors.foreground),
                            Flexible(child: Text(order.operation.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      cell(worker, _flexes.worker),
                      cell(book.machineOf(order)?.name ?? '—', _flexes.machine),
                      cell(formatInterval(order.interval), _flexes.interval),
                      Expanded(
                        flex: _flexes.status,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(stage: stage),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      OperationIcon(operation: order.operation, stage: stage, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${order.operation.label}, $parcel',
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$worker · ${formatInterval(order.interval)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(stage: stage),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
