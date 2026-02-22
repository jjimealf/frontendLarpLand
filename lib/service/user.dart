import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:larpland/model/user.dart';
import 'package:larpland/service/api_config.dart';
import 'package:larpland/service/auth_session.dart';

Future<List<User>> fetchUserList() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/users'),
    headers: _jsonHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception(
      'Fallo al cargar usuarios (${response.statusCode}): ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);
  final items = _extractUserList(decoded);
  return items
      .whereType<Map<String, dynamic>>()
      .map(User.fromJson)
      .toList(growable: false);
}

Future<User> showUser(int id) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/users/$id'),
    headers: _jsonHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('Fallo al cargar el usuario');
  }

  final decoded = jsonDecode(response.body);
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return User.fromJson(data);
    }
    return User.fromJson(decoded);
  }

  throw const FormatException('Fallo al cargar el usuario');
}

Map<String, String> _jsonHeaders() {
  final headers = <String, String>{
    'Accept': 'application/json',
  };
  final token = AuthSession.token;
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

List<dynamic> _extractUserList(dynamic decoded) {
  if (decoded is List) {
    return decoded;
  }
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is List) {
      return data;
    }
    final users = decoded['users'];
    if (users is List) {
      return users;
    }
  }
  return const [];
}
