part of 'work_report_form_bloc.dart';

final class WorkReportDraft extends Equatable {
  const WorkReportDraft({this.hectares = '', this.fuel = '', this.material = ''});

  final String hectares;
  final String fuel;
  final String material;

  WorkReportDraft copyWith({String? hectares, String? fuel, String? material}) => WorkReportDraft(
    hectares: hectares ?? this.hectares,
    fuel: fuel ?? this.fuel,
    material: material ?? this.material,
  );

  @override
  List<Object?> get props => [hectares, fuel, material];
}

sealed class WorkReportFormState extends Equatable {
  const WorkReportFormState({required this.draft});

  final WorkReportDraft draft;

  @override
  List<Object?> get props => [draft];

  @override
  String toString() => '$runtimeType';
}

final class WorkReportFormEditing extends WorkReportFormState {
  const WorkReportFormEditing({required super.draft, this.hectaresError, this.fuelError, this.materialError});

  final DomainError? hectaresError;
  final DomainError? fuelError;
  final DomainError? materialError;

  @override
  List<Object?> get props => [...super.props, hectaresError, fuelError, materialError];
}

final class WorkReportFormSubmitting extends WorkReportFormState {
  const WorkReportFormSubmitting({required super.draft});
}

final class WorkReportFormSucceeded extends WorkReportFormState {
  const WorkReportFormSucceeded({required super.draft});
}

final class WorkReportFormRejected extends WorkReportFormState {
  const WorkReportFormRejected({required super.draft, required this.error});

  final DomainError error;

  @override
  List<Object?> get props => [...super.props, error];
}

final class WorkReportFormFailed extends WorkReportFormState {
  const WorkReportFormFailed({required super.draft, required this.cause});

  final Object cause;

  @override
  List<Object?> get props => [...super.props, cause];
}
