import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support.dart';

void main() {
  late FakeRepository repository;

  Future<NewWorkOrderBloc> build() async {
    final bloc = NewWorkOrderBloc(
      planWorkOrder: PlanWorkOrder(repository: repository),
      book: await repository.workBook(),
      owner: owner,
      day: DateTime(2026, 11, 3),
    );
    await bloc.stream.first;
    return bloc;
  }

  setUp(() => repository = FakeRepository());

  test('a taken worker is flagged while choosing', () async {
    final bloc = await build();
    expect((bloc.state as NewWorkOrderEditing).error, const WorkerBusy());
    await bloc.close();
  });

  test('a free interval can be saved', () async {
    final bloc = await build();
    bloc.add(NewWorkOrderDraftChanged(bloc.state.draft.copyWith(startHour: 14, endHour: 18)));
    bloc.add(const NewWorkOrderSubmitted());
    final state = await bloc.stream.firstWhere((s) => s is NewWorkOrderSucceeded) as NewWorkOrderSucceeded;
    expect(state.order.status, const Planned());
    expect(repository.orders, hasLength(2));
    await bloc.close();
  });

  test('the end must come after the start', () async {
    final bloc = await build();
    bloc.add(NewWorkOrderDraftChanged(bloc.state.draft.copyWith(startHour: 14, endHour: 13)));
    final state = await bloc.stream.first as NewWorkOrderEditing;
    expect(state.error, const InvalidInterval());
    await bloc.close();
  });
}
