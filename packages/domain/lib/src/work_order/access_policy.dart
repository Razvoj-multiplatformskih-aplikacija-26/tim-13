import '../user.dart';
import 'work_order.dart';

abstract final class AccessPolicy {
  static bool canUseFieldApp(User user) => user.role == Role.worker;

  static bool canUseBackoffice(User user) => user.isOwner;

  static bool canView(User user, WorkOrder order) => user.isOwner || order.workerId == user.id;

  static bool canWorkOn(User user, WorkOrder order) => user.role == Role.worker && order.workerId == user.id;

  static bool canCancel(User user, WorkOrder order) => user.isOwner || order.workerId == user.id;

  static bool canDecide(User user) => user.isOwner;

  static bool canPlan(User user) => user.isOwner;
}
