import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const wide = 840.0;
}

abstract final class AgroTheme {
  static const seed = Color(0xFF2F6B3A);
  static const fontFamily = 'Inter';
  static const fontPackage = 'ui';
  static const background = Color(0xFFF5F6F0);

  static final radius = BorderRadius.circular(16);
  static final controlRadius = BorderRadius.circular(12);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(surface: background, surfaceTint: Colors.transparent);
    final base = ThemeData(colorScheme: scheme, fontFamily: fontFamily, package: fontPackage);
    final text = base.textTheme;
    final textTheme = text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final controlShape = RoundedRectangleBorder(borderRadius: controlRadius);
    const controlSize = Size(64, 48);
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) =>
              IconThemeData(color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            fontSize: 12,
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: controlSize, shape: controlShape, textStyle: textTheme.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: controlSize,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: controlShape)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: controlRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: Colors.white,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    );
  }
}

extension WorkOrderStageColors on WorkOrderStage {
  ({Color background, Color foreground}) get colors => switch (this) {
    WorkOrderStage.planned => (background: const Color(0xFFE3ECF7), foreground: const Color(0xFF1D4C80)),
    WorkOrderStage.inProgress => (background: const Color(0xFFFFEFCC), foreground: const Color(0xFF6E4B00)),
    WorkOrderStage.awaitingConfirmation => (background: const Color(0xFFEDE4F7), foreground: const Color(0xFF55307F)),
    WorkOrderStage.completed => (background: const Color(0xFFDDF0DF), foreground: const Color(0xFF1F5A2A)),
    WorkOrderStage.rejected => (background: const Color(0xFFFBE0DC), foreground: const Color(0xFF8A2318)),
    WorkOrderStage.cancelled => (background: const Color(0xFFE8E8E4), foreground: const Color(0xFF4A4A44)),
  };
}

extension AgroOperationIcon on AgroOperation {
  IconData get icon => switch (this) {
    AgroOperation.plowing => Icons.agriculture_outlined,
    AgroOperation.fertilizing => Icons.eco_outlined,
    AgroOperation.seedbedPreparation => Icons.grass_outlined,
    AgroOperation.sowing => Icons.spa_outlined,
    AgroOperation.spraying => Icons.water_drop_outlined,
    AgroOperation.harvesting => Icons.grain_outlined,
  };
}
