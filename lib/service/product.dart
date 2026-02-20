import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:larpland/model/product.dart';
import 'package:larpland/service/api_config.dart';
import 'package:path/path.dart';

Future<List<Product>> fetchProductList() async {
  try {
    final response =
        await http.get(Uri.parse('${ApiConfig.baseUrl}/api/products'));
    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    final items = _extractProductList(decoded);
    return items
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList(growable: false);
  } catch (_) {
    return [];
  }
}

Future<Product> addProduct(String name, String descripcion, String precio,
    int stock, String categoria, File imagen) async {
  // ignore: deprecated_member_use
  final stream = http.ByteStream(DelegatingStream.typed(imagen.openRead()));
  final length = await imagen.length();
  final multipartFile = http.MultipartFile(
    'file',
    stream,
    length,
    filename: basename(imagen.path),
  );
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConfig.baseUrl}/api/products'),
  )
    ..fields['nombre'] = name
    ..fields['descripcion'] = descripcion
    ..fields['precio'] = precio
    ..fields['cantidad'] = stock.toString()
    ..fields['categoria'] = categoria
    ..files.add(multipartFile);

  final streamedResponse = await request.send();
  final responseBody = await streamedResponse.stream.bytesToString();

  if (streamedResponse.statusCode == 200) {
    return Product.fromJson(jsonDecode(responseBody) as Map<String, dynamic>);
  } else {
    throw HttpException(
      'Fallo al agregar producto (${streamedResponse.statusCode})',
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
  File? imagen,
}) async {
  final Map<String, dynamic> body = {};
  if (name != null) {
    body['nombre'] = name;
  }
  if (descripcion != null) {
    body['descripcion'] = descripcion;
  }
  if (precio != null) {
    body['precio'] = precio;
  }
  if (stock != null) {
    body['cantidad'] = stock.toString();
  }
  if (categoria != null) {
    body['categoria'] = categoria;
  }
  if (imagen != null) {
    body['imagen'] = imagen.toString();
  }
  if (valoracionTotal != null) {
    body['valoracion_total'] = valoracionTotal;
  }

  final response = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/api/products/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(body),
  );
  if (response.statusCode != 200) {
    throw Exception('Fallo al actualizar producto');
  }
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
