class Login {
  final String status;
  final int rol;
  final String message;
  final int userId;

  const Login({
    required this.status,
    required this.rol,
    required this.message,
    required this.userId,
  });

  factory Login.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);

    final rawStatus = payload['status'] ?? payload['success'];
    final rawRole = payload['rol'] ?? payload['role'];
    final rawMessage = payload['message'] ?? payload['msg'] ?? '';
    final rawUserId = payload['userId'] ?? payload['user_id'] ?? payload['id'];

    final nestedUser = payload['user'];
    final nestedUserId = nestedUser is Map<String, dynamic>
        ? (nestedUser['id'] ?? nestedUser['userId'] ?? nestedUser['user_id'])
        : null;

    final rol = _parseInt(rawRole);
    final userId = _parseInt(rawUserId) ?? _parseInt(nestedUserId);
    final status = _parseStatus(rawStatus);
    final message = rawMessage is String ? rawMessage : rawMessage.toString();

    if (rol == null || userId == null) {
      throw Exception('Login invalido');
    }

    return Login(
      status: status,
      rol: rol,
      message: message,
      userId: userId,
    );
  }
}

Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }
  return json;
}

int? _parseInt(dynamic value) {
  return switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };
}

String _parseStatus(dynamic value) {
  return switch (value) {
    String v => v,
    bool v => v ? 'success' : 'error',
    num v => v == 1 ? 'success' : 'error',
    _ => 'success',
  };
}
