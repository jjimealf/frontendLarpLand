import 'dart:convert';

import 'package:larpland/model/login.dart';
import 'package:http/http.dart' as http;

Future<Login> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/api/login'),
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
    return Login.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Login fallido');
  }
}
