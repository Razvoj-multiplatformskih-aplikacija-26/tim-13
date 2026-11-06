abstract final class ApiPaths {
  static const health = '/health';
  static const sessions = '/api/v1/sessions';
  static const currentSession = '/api/v1/sessions/current';
  static const workBook = '/api/v1/work-book';
  static const workOrders = '/api/v1/work-orders';

  static String workOrder(String id) => '$workOrders/$id';

  static String start(String id) => '${workOrder(id)}/start';

  static String report(String id) => '${workOrder(id)}/report';

  static String cancellation(String id) => '${workOrder(id)}/cancellation';

  static String approval(String id) => '${workOrder(id)}/approval';

  static String rejection(String id) => '${workOrder(id)}/rejection';
}

abstract final class ApiCookies {
  static const session = 'agroflow_session';
}
