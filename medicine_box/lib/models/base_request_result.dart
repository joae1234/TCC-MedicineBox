class BaseRequestResult<T> {
  final bool hasError;
  final String? errorMessage;
  final T? data;

  BaseRequestResult({required this.hasError, this.errorMessage, this.data});

  factory BaseRequestResult.success(T data) =>
      BaseRequestResult(hasError: false, data: data);

  factory BaseRequestResult.failure(String message) =>
      BaseRequestResult(hasError: true, errorMessage: message);

  factory BaseRequestResult.fromMap(
    Map<String, dynamic> map, {
    T Function(dynamic json)? fromJson,
  }) {
    return BaseRequestResult<T>(
      hasError: map['hasError'] ?? false,
      errorMessage: map['errorMessage'],
      data:
          fromJson != null && map['data'] != null
              ? fromJson(map['data'])
              : map['data'],
    );
  }

  Map<String, dynamic> toMap() => {
    'error': hasError,
    'errorMessage': errorMessage,
    'data': data,
  };
}
