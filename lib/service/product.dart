import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/api_config.dart';
import 'package:larpland/service/auth_session.dart';

Future<List<Product>> fetchProductList() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/products'),
    headers: _jsonHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception(
      'Fallo al cargar productos (${response.statusCode}): ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);
  final items = _extractProductList(decoded);
  return items
      .whereType<Map<String, dynamic>>()
      .map(Product.fromJson)
      .toList(growable: false);
}

Future<void> addProduct(
  String name,
  String descripcion,
  String precio,
  int stock,
  String categoria,
  XFile imagen,
) async {
  final Uint8List bytes = await imagen.readAsBytes();
  final multipartFile = http.MultipartFile.fromBytes(
    'imagen',
    bytes,
    filename: imagen.name,
  );
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConfig.baseUrl}/api/products'),
  )
    ..headers.addAll(_jsonHeaders())
    ..fields['nombre'] = name
    ..fields['descripcion'] = descripcion
    ..fields['precio'] = precio
    ..fields['cantidad'] = stock.toString()
    ..fields['categoria'] = categoria
    ..files.add(multipartFile);

  final streamedResponse = await request.send();
  final responseBody = await streamedResponse.stream.bytesToString();

  if (streamedResponse.statusCode != 200 &&
      streamedResponse.statusCode != 201) {
    throw Exception(
      'Fallo al agregar producto (${streamedResponse.statusCode}): $responseBody',
    );
  }
}

Future<void> updateProduct(
  int id, {
  String? name,
  String? descripcion,
  String? precio,
  String? valoracionTotal,
  int? stock,
  String? categoria,
  XFile? imagen,
}) async {
  if (imagen != null) {
    await _updateProductWithImage(
      id,
      name: name,
      descripcion: descripcion,
      precio: precio,
      valoracionTotal: valoracionTotal,
      stock: stock,
      categoria: categoria,
      imagen: imagen,
    );
    return;
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConfig.baseUrl}/api/products/$id'),
  )
    ..headers.addAll(_jsonHeaders())
    ..fields['_method'] = 'PUT';

  if (name != null) {
    request.fields['nombre'] = name;
  }
  if (descripcion != null) {
    request.fields['descripcion'] = descripcion;
  }
  if (precio != null) {
    request.fields['precio'] = precio;
  }
  if (stock != null) {
    request.fields['cantidad'] = stock.toString();
  }
  if (categoria != null) {
    request.fields['categoria'] = categoria;
  }
  if (valoracionTotal != null) {
    request.fields['valoracion_total'] = valoracionTotal;
    request.fields['valoracionTotal'] = valoracionTotal;
  }

  final streamedResponse = await request.send();
  if (streamedResponse.statusCode != 200 &&
      streamedResponse.statusCode != 201) {
    final body = await streamedResponse.stream.bytesToString();
    throw Exception(
      'Fallo al actualizar producto (${streamedResponse.statusCode}): $body',
    );
  }
}

Future<void> deleteProduct(int id) async {
  final response = await http.delete(
    Uri.parse('${ApiConfig.baseUrl}/api/products/$id'),
    headers: _jsonHeaders(),
  );

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception(
      'Fallo al borrar producto (${response.statusCode}): ${response.body}',
    );
  }
}

Future<void> _updateProductWithImage(
  int id, {
  String? name,
  String? descripcion,
  String? precio,
  String? valoracionTotal,
  int? stock,
  String? categoria,
  required XFile imagen,
}) async {
  final Uint8List bytes = await imagen.readAsBytes();
  final multipartFile = http.MultipartFile.fromBytes(
    'imagen',
    bytes,
    filename: imagen.name,
  );

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConfig.baseUrl}/api/products/$id'),
  )
    ..headers.addAll(_jsonHeaders())
    ..fields['_method'] = 'PUT'
    ..files.add(multipartFile);

  if (name != null) {
    request.fields['nombre'] = name;
  }
  if (descripcion != null) {
    request.fields['descripcion'] = descripcion;
  }
  if (precio != null) {
    request.fields['precio'] = precio;
  }
  if (stock != null) {
    request.fields['cantidad'] = stock.toString();
  }
  if (categoria != null) {
    request.fields['categoria'] = categoria;
  }
  if (valoracionTotal != null) {
    request.fields['valoracion_total'] = valoracionTotal;
    request.fields['valoracionTotal'] = valoracionTotal;
  }

  final streamedResponse = await request.send();
  if (streamedResponse.statusCode != 200 &&
      streamedResponse.statusCode != 201) {
    final body = await streamedResponse.stream.bytesToString();
    throw Exception(
      'Fallo al actualizar producto (${streamedResponse.statusCode}): $body',
    );
  }
}

Map<String, String> _jsonHeaders() {
  return {
    'Accept': 'application/json',
    ..._authHeader(),
  };
}

Map<String, String> _authHeader() {
  final token = AuthSession.token;
  if (token == null || token.isEmpty) {
    return const {};
  }
  return {'Authorization': 'Bearer $token'};
}

List<dynamic> _extractProductList(dynamic decoded) {
  if (decoded is List) {
    return decoded;
  }
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is List) {
      return data;
    }
    final products = decoded['products'];
    if (products is List) {
      return products;
    }
  }
  return const [];
}
