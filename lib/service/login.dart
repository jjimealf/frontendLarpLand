import 'dart:convert';

import 'package:larpland/model/login.dart';
import 'package:http/http.dart' as http;
import 'package:larpland/service/api_config.dart';
import 'package:larpland/service/auth_session.dart';

Future<Login> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/login'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );
  if (response.statusCode == 200) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final loginResult = Login.fromJson(decoded);
        AuthSession.token = loginResult.token;
        return loginResult;
      }
      throw Exception('Respuesta de login no es un objeto JSON');
    } catch (e) {
      throw Exception('Login invalido. Respuesta: ${response.body}');
    }
  } else {
    throw Exception('Login fallido (${response.statusCode}): ${response.body}');
  }
}
