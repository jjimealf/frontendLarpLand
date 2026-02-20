import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/api_config.dart';

Future<List<RoleplayEvent>> fetchEventList() async {
  try {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/events'));
    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    final items = _extractEventList(decoded);
    return items
        .whereType<Map<String, dynamic>>()
        .map(RoleplayEvent.fromJson)
        .toList(growable: false);
  } catch (_) {
    return [];
  }
}

Future<RoleplayEvent> addEvent(
  String name,
  String description,
  String fechaInicio,
  String fechaFin,
) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/events'),
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

List<dynamic> _extractEventList(dynamic decoded) {
  if (decoded is List) {
    return decoded;
  }
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is List) {
      return data;
    }
    final events = decoded['events'];
    if (events is List) {
      return events;
    }
  }
  return const [];
}
