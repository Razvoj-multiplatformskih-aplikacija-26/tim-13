import 'package:equatable/equatable.dart';

import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';

final class MaterialUse extends Equatable {
  const MaterialUse._(this.item, this.quantity);

  final StockItemId item;
  final int quantity;

  static Result<MaterialUse> parse(StockItemId item, String input) {
    final quantity = int.tryParse(input.trim());
    if (quantity == null || quantity <= 0) return const Failure(InvalidMaterialQuantity());
    return Success(MaterialUse._(item, quantity));
  }

  @override
  List<Object?> get props => [item, quantity];
}
