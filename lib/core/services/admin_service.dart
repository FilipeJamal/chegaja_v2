import 'package:cloud_functions/cloud_functions.dart';
import 'package:chegaja_v2/core/config/app_config.dart';

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: AppConfig.functionsRegion,
  );

  HttpsCallable _callable(String name) => _functions.httpsCallable(name);

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asListOfMaps(Object? value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.map((item) => _asMap(item)).toList();
  }

  Future<Map<String, dynamic>> getDashboardSnapshot() async {
    final res = await _callable('admin_getDashboardSnapshot').call();
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> getOpsMetrics({int days = 30}) async {
    final res = await _callable('admin_getOpsMetrics').call({'days': days});
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> getCostRetentionSnapshot() async {
    final res = await _callable('admin_getCostRetentionSnapshot').call();
    return _asMap(res.data);
  }

  Future<List<Map<String, dynamic>>> listSupportTickets({
    String status = 'all',
    int limit = 50,
  }) async {
    final res = await _callable('admin_listSupportTickets').call({
      'status': status,
      'limit': limit,
    });
    final map = _asMap(res.data);
    return _asListOfMaps(map['tickets']);
  }

  Future<void> updateSupportTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    await _callable('admin_updateSupportTicketStatus').call({
      'ticketId': ticketId,
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> listNoShowCases({
    String decision = 'pending',
    int limit = 50,
  }) async {
    final res = await _callable('admin_listNoShowCases').call({
      'decision': decision,
      'limit': limit,
    });
    final map = _asMap(res.data);
    return _asListOfMaps(map['cases']);
  }

  Future<void> setNoShowDecision({
    required String pedidoId,
    required String decision,
  }) async {
    await _callable('admin_setNoShowDecision').call({
      'pedidoId': pedidoId,
      'decision': decision,
    });
  }

  Future<List<Map<String, dynamic>>> listStories({
    int limit = 50,
  }) async {
    final res = await _callable('admin_listStories').call({
      'limit': limit,
    });
    final map = _asMap(res.data);
    return _asListOfMaps(map['stories']);
  }

  Future<void> deleteStory({
    required String storyId,
  }) async {
    await _callable('admin_deleteStory').call({
      'storyId': storyId,
    });
  }

  Future<List<Map<String, dynamic>>> getLedgerAnomalies({
    int limit = 50,
  }) async {
    final res = await _callable('admin_getLedgerAnomalies').call({
      'limit': limit,
    });
    final map = _asMap(res.data);
    return _asListOfMaps(map['anomalies']);
  }
}
