import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';

class ProviderServicePolicyResult {
  const ProviderServicePolicyResult({
    required this.serviceIds,
    required this.pendingSensitiveIds,
    required this.pendingCustomIds,
    required this.blockedCustomCount,
  });

  final List<String> serviceIds;
  final List<String> pendingSensitiveIds;
  final List<String> pendingCustomIds;
  final int blockedCustomCount;

  bool get hasPendingReview =>
      pendingSensitiveIds.isNotEmpty || pendingCustomIds.isNotEmpty;
}

class ProviderServicePolicyService {
  ProviderServicePolicyService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  Future<ProviderServicePolicyResult> updateServices({
    required List<String> serviceIds,
    required List<Map<String, dynamic>> customServices,
  }) async {
    final response = await _functions
        .httpsCallable('providers_updateServices')
        .call(<String, dynamic>{
      'serviceIds': serviceIds,
      'customServices': customServices,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return ProviderServicePolicyResult(
      serviceIds: _strings(data['serviceIds']),
      pendingSensitiveIds: _strings(data['pendingSensitiveIds']),
      pendingCustomIds: _strings(data['pendingCustomIds']),
      blockedCustomCount: (data['blockedCustomCount'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! Iterable) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
