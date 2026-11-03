import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support.dart';

void main() {
  late FakeRepository repository;

  WorkOrdersBoardBloc build() => WorkOrdersBoardBloc(
    getWorkBook: GetWorkBook(repository: repository),
    approveWorkOrder: ApproveWorkOrder(repository: repository, clock: FixedClock(now)),
    rejectWorkOrder: RejectWorkOrder(repository: repository, clock: FixedClock(now)),
    cancelWorkOrder: CancelWorkOrder(repository: repository, clock: FixedClock(now)),
    owner: owner,
  );

  Future<WorkOrdersBoardBloc> loaded() async {
    final bloc = build()..add(const BoardRequested());
    await bloc.stream.firstWhere((s) => s is BoardLoaded);
    return bloc;
  }

  setUp(() => repository = FakeRepository(orders: [awaiting('a1'), plowing, fertilizing]));

  test('the cursor stays inside the list', () async {
    final bloc = await loaded();
    bloc.add(const BoardCursorMoved(-1));
    bloc.add(const BoardCursorMoved(5));
    final state = await bloc.stream.firstWhere((s) => s is BoardLoaded && s.cursor == 2) as BoardLoaded;
    expect(state.orderAtCursor, fertilizing);
    await bloc.close();
  });

  test('activating the cursor selects the order', () async {
    final bloc = await loaded();
    bloc.add(const BoardCursorActivated());
    final state = await bloc.stream.firstWhere((s) => s is BoardLoaded && s.selectedId != null) as BoardLoaded;
    expect(state.selected?.id.value, 'a1');
    await bloc.close();
  });

  test('an unknown selection is ignored', () async {
    final bloc = await loaded();
    bloc.add(const BoardOrderSelected(WorkOrderId('x')));
    bloc.add(BoardOrderSelected(plowing.id));
    final state = await bloc.stream.firstWhere((s) => s is BoardLoaded && s.selectedId != null) as BoardLoaded;
    expect(state.selectedId, plowing.id);
    await bloc.close();
  });

  test('a filter keeps the selection and narrows the list', () async {
    final bloc = await loaded();
    bloc.add(BoardOrderSelected(plowing.id));
    bloc.add(const BoardFilterChanged(WorkOrderStage.planned));
    final state = await bloc.stream.firstWhere((s) => s is BoardLoaded && s.filter != null) as BoardLoaded;
    expect(state.visible, hasLength(2));
    expect(state.selectedId, plowing.id);
    await bloc.close();
  });

  test('approving keeps the selection and reports success', () async {
    final bloc = await loaded();
    const id = WorkOrderId('a1');
    bloc.add(const BoardOrderSelected(id));
    bloc.add(const BoardApprovalRequested(id));
    final state = await bloc.stream.firstWhere((s) => s is BoardLoaded && s.notice != null) as BoardLoaded;
    expect(state.notice, isA<BoardActionSucceeded>());
    expect(state.selected?.status, isA<Completed>());
    await bloc.close();
  });

  test('rejection needs the owner flow and stores the reason', () async {
    final bloc = await loaded();
    const id = WorkOrderId('a1');
    final reason = ReasonText.parse('Pogrešna površina').valueOrNull!;
    bloc.add(BoardRejectionRequested(id, reason: reason));
    final state = await bloc.stream.firstWhere((s) => s is BoardLoaded && s.notice != null) as BoardLoaded;
    expect((state.book.find(id)?.status as Rejected?)?.reason, reason);
    await bloc.close();
  });

  test('an impossible action is rejected with the domain error', () async {
    final bloc = await loaded();
    bloc.add(BoardApprovalRequested(plowing.id));
    final state = await bloc.stream.firstWhere((s) => s is BoardLoaded && s.notice != null) as BoardLoaded;
    expect(state.notice, isA<BoardActionRejected>());
    await bloc.close();
  });

  test('an empty book gives the empty state', () async {
    repository = FakeRepository(orders: const []);
    final bloc = build()..add(const BoardRequested());
    await bloc.stream.firstWhere((s) => s is BoardEmpty);
    await bloc.close();
  });
}
