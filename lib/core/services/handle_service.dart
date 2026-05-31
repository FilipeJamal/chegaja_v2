import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/models/public_handle.dart';

typedef HandleFunctionCaller = Future<Map<String, dynamic>> Function(
  String name,
  Map<String, dynamic> payload,
);

class HandleAvailability {
  const HandleAvailability({
    required this.normalizedHandle,
    required this.available,
    required this.reason,
    required this.message,
  });

  final String normalizedHandle;
  final bool available;
  final String reason;
  final String message;
}

class HandleService {
  HandleService({
    FirebaseFunctions? functions,
    HandleFunctionCaller? callFunction,
  })  : _functions = functions,
        _callFunction = callFunction;

  static final HandleService instance = HandleService();

  final FirebaseFunctions? _functions;
  final HandleFunctionCaller? _callFunction;

  Future<HandleAvailability> checkAvailability(String rawHandle) async {
    final data = await _call('handle_checkAvailability', {
      'handle': rawHandle,
    });
    return HandleAvailability(
      normalizedHandle: _readString(data['normalizedHandle']),
      available: data['available'] == true,
      reason: _readString(data['reason']),
      message: _readString(data['message']),
    );
  }

  Future<PublicHandle> reserveProviderHandle(String rawHandle) async {
    final data = await _call('handle_reserveProviderHandle', {
      'handle': rawHandle,
    });
    final handle = PublicHandle.fromMap(
      id: _readString(data['handle']),
      data: <String, dynamic>{
        ...data,
        'role': data['role'] ?? 'prestador',
      },
    );
    if (handle == null) {
      throw StateError('Resposta invalida ao reservar @handle.');
    }
    return handle;
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final injected = _callFunction;
    if (injected != null) {
      return injected(name, payload);
    }
    final functions = _functions ??
        FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);
    final res = await functions.httpsCallable(name).call(payload);
    return _asMap(res.data);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }

  static String _readString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
