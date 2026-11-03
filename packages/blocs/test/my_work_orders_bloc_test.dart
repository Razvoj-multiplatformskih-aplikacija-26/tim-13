import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support.dart';

void main() {
  late FakeRepository repository;

  MyWorkOrdersBloc build() => MyWorkOrdersBloc(
    getWorkBook: GetWorkBook(repository: repository),
    startWorkOrder: StartWorkOrder(repository: repository, clock: FixedClock(now)),
    cancelWorkOrder: CancelWorkOrder(repository: repository, clock: FixedClock(now)),
    worker: worker,
  );

  setUp(() => repository = FakeRepository());

  blocTest<MyWorkOrdersBloc, MyWorkOrdersState>(
    'goes from loading to the data',
    build: build,
    act: (bloc) => bloc.add(const MyWorkOrdersRequested()),
    expect: () => [isA<MyWorkOrdersLoading>(), isA<MyWorkOrdersLoaded>()],
  );

  blocTest<MyWorkOrdersBloc, MyWorkOrdersState>(
    'reports a repository failure',
    build: build,
    setUp: () => repository = FakeRepository()..failing = true,
    act: (bloc) => bloc.add(const MyWorkOrdersRequested()),
    expect: () => [isA<MyWorkOrdersLoading>(), isA<MyWorkOrdersFailure>()],
  );

  blocTest<MyWorkOrdersBloc, MyWorkOrdersState>(
    'reports an empty result',
    build: build,
    setUp: () => repository = FakeRepository(orders: const []),
    act: (bloc) => bloc.add(const MyWorkOrdersRequested()),
    expect: () => [isA<MyWorkOrdersLoading>(), isA<MyWorkOrdersEmpty>()],
  );

  test('starting an order reloads it with a notice', () async {
    final bloc = build()..add(const MyWorkOrdersRequested());
    await bloc.stream.firstWhere((s) => s is MyWorkOrdersLoaded);
    bloc.add(WorkOrderStartRequested(plowing.id));
    final done = await bloc.stream.firstWhere((s) => s is MyWorkOrdersLoaded && s.notice != null) as MyWorkOrdersLoaded;
    expect(done.notice, const WorkOrderStarted());
    expect(done.book.find(plowing.id)?.status, isA<InProgress>());
    await bloc.close();
  });

  test('a blocked start keeps the data and explains why', () async {
    repository = FakeRepository(orders: [fertilizing]);
    final bloc = build()..add(const MyWorkOrdersRequested());
    await bloc.stream.firstWhere((s) => s is MyWorkOrdersLoaded);
    bloc.add(WorkOrderStartRequested(fertilizing.id));
    final done = await bloc.stream.firstWhere((s) => s is MyWorkOrdersLoaded && s.notice != null) as MyWorkOrdersLoaded;
    expect(done.notice, const WorkOrderActionRejected(PreviousPhaseNotDone(AgroOperation.plowing)));
    await bloc.close();
  });
}
