part of 'work_report_form_bloc.dart';

sealed class WorkReportFormEvent {
  const WorkReportFormEvent();
}

final class WorkReportHectaresChanged extends WorkReportFormEvent {
  const WorkReportHectaresChanged(this.text);

  final String text;
}

final class WorkReportFuelChanged extends WorkReportFormEvent {
  const WorkReportFuelChanged(this.text);

  final String text;
}

final class WorkReportMaterialChanged extends WorkReportFormEvent {
  const WorkReportMaterialChanged(this.text);

  final String text;
}

final class WorkReportSubmitted extends WorkReportFormEvent {
  const WorkReportSubmitted();
}
