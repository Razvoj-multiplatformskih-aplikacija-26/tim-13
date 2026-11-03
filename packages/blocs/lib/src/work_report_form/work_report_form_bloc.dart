import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'work_report_form_event.dart';
part 'work_report_form_state.dart';

final class WorkReportFormBloc extends Bloc<WorkReportFormEvent, WorkReportFormState> {
  WorkReportFormBloc({
    required this.submitWorkReport,
    required this.worker,
    required this.order,
    required this.remaining,
  }) : super(const WorkReportFormEditing(draft: WorkReportDraft())) {
    on<WorkReportHectaresChanged>((event, emit) => emit(_editing(state.draft.copyWith(hectares: event.text))));
    on<WorkReportFuelChanged>((event, emit) => emit(_editing(state.draft.copyWith(fuel: event.text))));
    on<WorkReportMaterialChanged>((event, emit) => emit(_editing(state.draft.copyWith(material: event.text))));
    on<WorkReportSubmitted>(_onSubmitted);
  }

  final SubmitWorkReport submitWorkReport;
  final User worker;
  final WorkOrder order;
  final Hectares remaining;

  StockItemId? get _materialItem => order.material?.item;

  Result<Hectares> _hectares(String text) => switch (Hectares.parse(text)) {
    Failure(:final error) => Failure(error),
    Success(:final value) => checkReportedArea(value, remaining: remaining),
  };

  Result<MaterialUse>? _material(String text) {
    final item = _materialItem;
    return item == null ? null : MaterialUse.parse(item, text);
  }

  DomainError? _ifEntered(String text, DomainError? error) => text.trim().isEmpty ? null : error;

  WorkReportFormEditing _editing(WorkReportDraft draft) => WorkReportFormEditing(
    draft: draft,
    hectaresError: _ifEntered(draft.hectares, _hectares(draft.hectares).errorOrNull),
    fuelError: _ifEntered(draft.fuel, FuelLiters.parse(draft.fuel).errorOrNull),
    materialError: _ifEntered(draft.material, _material(draft.material)?.errorOrNull),
  );

  Future<void> _onSubmitted(WorkReportSubmitted event, Emitter<WorkReportFormState> emit) async {
    final draft = state.draft;
    final hectares = _hectares(draft.hectares);
    final fuel = FuelLiters.parse(draft.fuel);
    final material = _material(draft.material);
    if (hectares is Failure || fuel is Failure || material is Failure) {
      emit(
        WorkReportFormEditing(
          draft: draft,
          hectaresError: hectares.errorOrNull,
          fuelError: fuel.errorOrNull,
          materialError: material?.errorOrNull,
        ),
      );
      return;
    }
    emit(WorkReportFormSubmitting(draft: draft));
    try {
      final result = await submitWorkReport(
        id: order.id,
        processed: hectares.valueOrNull!,
        fuel: fuel.valueOrNull!,
        material: material?.valueOrNull,
        by: worker,
      );
      emit(switch (result) {
        Success() => WorkReportFormSucceeded(draft: draft),
        Failure(:final error) => WorkReportFormRejected(draft: draft, error: error),
      });
    } on Exception catch (cause) {
      emit(WorkReportFormFailed(draft: draft, cause: cause));
    }
  }
}
