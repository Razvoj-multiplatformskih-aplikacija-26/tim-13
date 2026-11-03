import 'package:equatable/equatable.dart';

import '../identifiers.dart';

enum StockKind { fertilizer, chemical }

enum StockUnit { kilogram, liter }

final class StockItem extends Equatable {
  const StockItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.unit,
    required this.available,
  });

  final StockItemId id;
  final String name;
  final StockKind kind;
  final StockUnit unit;
  final int available;

  @override
  List<Object?> get props => [id, name, kind, unit, available];
}
