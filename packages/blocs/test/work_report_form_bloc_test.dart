import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support.dart';

void main() {
  final running = plowing.withStatus(InProgress(startedAt: now));
  late FakeRepository repository;

  WorkReportFormBloc build() => WorkReportFormBloc(
    submitWorkReport: SubmitWorkReport(repository: repository, clock: FixedClock(now)),
    worker: worker,
    order: running,
    remaining: area,
  );

  setUp(() => repository = FakeRepository(orders: [running]));

  test('a value above the remaining area is flagged while typing', () async {
    final bloc = build()..add(const WorkReportHectaresChanged('10.5'));
    final state = await bloc.stream.first as WorkReportFormEditing;
    expect(state.hectaresError, ExceedsParcelArea(area));
    await bloc.close();
  });

  test('an empty field is not an error until submit', () async {
    final bloc = build()..add(const WorkReportHectaresChanged('  '));
    expect((await bloc.stream.first as WorkReportFormEditing).hectaresError, isNull);
    bloc.add(const WorkReportSubmitted());
    final state = await bloc.stream.first as WorkReportFormEditing;
    expect(state.hectaresError, const InvalidHectares());
    expect(state.fuelError, const InvalidFuelAmount());
    await bloc.close();
  });

  test('a valid report is sent', () async {
    final bloc = build()
      ..add(const WorkReportHectaresChanged('10'))
      ..add(const WorkReportFuelChanged('50'))
      ..add(const WorkReportSubmitted());
    await bloc.stream.firstWhere((s) => s is WorkReportFormSucceeded);
    expect(repository.orders.single.status, isA<AwaitingConfirmation>());
    await bloc.close();
  });

  test('a repository failure keeps the draft', () async {
    repository.failing = true;
    final bloc = build()
      ..add(const WorkReportHectaresChanged('10'))
      ..add(const WorkReportFuelChanged('50'))
      ..add(const WorkReportSubmitted());
    final state = await bloc.stream.firstWhere((s) => s is WorkReportFormFailed);
    expect(state.draft.hectares, '10');
    await bloc.close();
  });
}
