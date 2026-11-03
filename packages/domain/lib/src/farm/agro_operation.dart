import 'stock_item.dart';

enum AgroOperation {
  plowing,
  fertilizing,
  seedbedPreparation,
  sowing,
  spraying,
  harvesting;

  AgroOperation? get previous => index == 0 ? null : values[index - 1];

  StockKind? get requiredStock => switch (this) {
    fertilizing => StockKind.fertilizer,
    spraying => StockKind.chemical,
    plowing || seedbedPreparation || sowing || harvesting => null,
  };

  bool get requiresStock => requiredStock != null;
}
