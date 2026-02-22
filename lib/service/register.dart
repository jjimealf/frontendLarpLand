import 'dart:convert';

import 'package:larpland/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:larpland/service/api_config.dart';

Future<User> register(String name, String email, String password) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/register'),
    headers: {
      'Accept': 'application/json',
    },
    body: {
      'name': name,
      'email': email,
      'password': password,
    },
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final userPayload = _extractUserPayload(decoded);
      if (userPayload != null) {
        return User.fromJson(userPayload);
      }
    }

    // Some backends return only a success message on register.
    return User(id: 0, name: name, email: email);
  } else {
    throw Exception(
      'Registro fallido (${response.statusCode}): ${response.body}',
    );
  }
}

Map<String, dynamic>? _extractUserPayload(Map<String, dynamic> json) {
  if (json['id'] != null && json['name'] != null && json['email'] != null) {
    return json;
  }

  final user = json['user'];
  if (user is Map<String, dynamic>) {
    return user;
  }

  final data = json['data'];
  if (data is Map<String, dynamic>) {
    if (data['id'] != null && data['name'] != null && data['email'] != null) {
      return data;
    }
    final nestedUser = data['user'];
    if (nestedUser is Map<String, dynamic>) {
      return nestedUser;
    }
  }

  return null;
}
