import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/api_config.dart';
import 'package:larpland/service/auth_session.dart';

Future<List<RoleplayEvent>> fetchEventList() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/events'),
    headers: _jsonHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception(
      'Fallo al cargar eventos (${response.statusCode}): ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);
  final items = _extractEventList(decoded);
  return items
      .whereType<Map<String, dynamic>>()
      .map(RoleplayEvent.fromJson)
      .toList(growable: false);
}

Future<RoleplayEvent> addEvent(
  String name,
  String description,
  String fechaInicio,
  String fechaFin,
) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/events'),
    headers: _jsonHeaders(),
    body: {
      'nombre': name,
      'descripcion': description,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    },
  );
  if (response.statusCode == 200) {
    return RoleplayEvent.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  } else {
    throw Exception('Fallo al agregar evento');
  }
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

List<dynamic> _extractEventList(dynamic decoded) {
  if (decoded is List) {
    return decoded;
  }
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final nested = _extractEventList(data);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
    final events = decoded['events'];
    if (events is List) {
      return events;
    }
    if (events is Map<String, dynamic>) {
      final nested = _extractEventList(events);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
  }
  return const [];
}
