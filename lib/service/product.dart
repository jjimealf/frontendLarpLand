import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/firebase_backend.dart';
import 'package:path/path.dart' as p;

Future<List<Product>> fetchProductList() async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await FirebaseBackend.products.orderBy('id').get();
  return snapshot.docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map(_coerceProductPayload)
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
  FirebaseBackend.ensureInitialized();
  final productId = await FirebaseBackend.nextNumericId('products');
  final imageUrl = await _uploadProductImage(imagen, productId: productId);
  final now = FieldValue.serverTimestamp();

  await FirebaseBackend.products.add(<String, dynamic>{
    'id': productId,
    'nombre': name.trim(),
    'descripcion': descripcion.trim(),
    'precio': precio.trim(),
    'imagen': imageUrl,
    'cantidad': stock,
    'valoracion_total': '0.0',
    'categoria': categoria.trim(),
    'created_at': now,
    'updated_at': now,
  });
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
  FirebaseBackend.ensureInitialized();
  final doc = await FirebaseBackend.findByNumericId(FirebaseBackend.products, id);
  final current = doc.data() ?? const <String, dynamic>{};

  String? imageUrl;
  if (imagen != null) {
    imageUrl = await _uploadProductImage(imagen, productId: id);
    final previous = current['imagen'];
    if (previous is String && previous.startsWith('http')) {
      await _tryDeleteStorageUrl(previous);
    }
  }

  final updates = <String, dynamic>{
    if (name != null) 'nombre': name.trim(),
    if (descripcion != null) 'descripcion': descripcion.trim(),
    if (precio != null) 'precio': precio.trim(),
    if (stock != null) 'cantidad': stock,
    if (categoria != null) 'categoria': categoria.trim(),
    if (valoracionTotal != null) 'valoracion_total': valoracionTotal,
    if (imageUrl != null) 'imagen': imageUrl,
    'updated_at': FieldValue.serverTimestamp(),
  };

  if (updates.length == 1) {
    // Only updated_at would be sent; avoid pointless write in callers.
    return;
  }

  await doc.reference.set(updates, SetOptions(merge: true));
}

Future<void> deleteProduct(int id) async {
  FirebaseBackend.ensureInitialized();
  final doc = await FirebaseBackend.findByNumericId(FirebaseBackend.products, id);
  final data = doc.data();
  final imageUrl = data?['imagen'];
  if (imageUrl is String && imageUrl.startsWith('http')) {
    await _tryDeleteStorageUrl(imageUrl);
  }
  await doc.reference.delete();
}

Future<String> _uploadProductImage(
  XFile imagen, {
  required int productId,
}) async {
  final Uint8List bytes = await imagen.readAsBytes();
  final extension = p.extension(imagen.name).toLowerCase();
  final normalizedExt = extension.isEmpty ? '.jpg' : extension;
  final path =
      'products/$productId/${DateTime.now().millisecondsSinceEpoch}$normalizedExt';
  final ref = FirebaseBackend.storage.ref(path);

  final metadata = SettableMetadata(
    contentType: _contentTypeFromExtension(normalizedExt),
  );
  try {
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  } on FirebaseException catch (e) {
    switch (e.code) {
      case 'object-not-found':
        throw Exception(
          'Firebase Storage no encontro el archivo tras subirlo. Revisa si Storage esta habilitado y si storageBucket en firebase_options.dart es correcto.',
        );
      case 'unauthorized':
      case 'permission-denied':
        throw Exception(
          'Firebase Storage denego permisos. Revisa las reglas de Storage.',
        );
      case 'bucket-not-found':
        throw Exception(
          'El bucket de Firebase Storage no existe. Verifica storageBucket en firebase_options.dart.',
        );
      default:
        throw Exception(
          e.message == null || e.message!.trim().isEmpty
              ? 'Error de Firebase Storage (${e.code}).'
              : 'Error de Firebase Storage (${e.code}): ${e.message}',
        );
    }
  }
}

String _contentTypeFromExtension(String ext) {
  switch (ext) {
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.jpeg':
    case '.jpg':
    default:
      return 'image/jpeg';
  }
}

Future<void> _tryDeleteStorageUrl(String url) async {
  try {
    final ref = FirebaseStorage.instance.refFromURL(url);
    await ref.delete();
  } catch (_) {
    // Ignorar errores de limpieza para no bloquear la operacion principal.
  }
}

Map<String, dynamic> _coerceProductPayload(Map<String, dynamic> data) {
  final normalized = <String, dynamic>{...data};
  normalized['id'] = _asInt(normalized['id']) ?? 0;
  normalized['nombre'] = '${normalized['nombre'] ?? ''}';
  normalized['descripcion'] = '${normalized['descripcion'] ?? ''}';
  normalized['precio'] = '${normalized['precio'] ?? ''}';
  normalized['imagen'] = '${normalized['imagen'] ?? ''}';
  normalized['cantidad'] = _asInt(normalized['cantidad']) ?? 0;
  normalized['valoracion_total'] = '${normalized['valoracion_total'] ?? '0.0'}';
  normalized['categoria'] = '${normalized['categoria'] ?? ''}';
  return normalized;
}

int? _asInt(dynamic value) {
  return switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };
}
