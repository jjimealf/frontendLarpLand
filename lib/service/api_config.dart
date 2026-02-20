import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      final scheme = Uri.base.scheme;

      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return '$scheme://$host:8000';
      }

      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps host machine localhost to 10.0.2.2.
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  static String resolveImageUrl(String rawPath) {
    final urls = resolveImageCandidates(rawPath);
    if (urls.isEmpty) {
      return '';
    }
    return urls.first;
  }

  static List<String> resolveImageCandidates(String rawPath) {
    final path = rawPath.trim();
    if (path.isEmpty) {
      return const [];
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return [path];
    }

    final normalized = path.replaceAll('\\', '/');
    final canonical = normalized.replaceFirst(RegExp(r'^/+'), '');
    final imagePath = canonical.replaceFirst('public/', 'storage/');
    final fileName = canonical.split('/').last;
    final candidates = <String>{};

    // Prioritize Laravel public->storage mapping:
    // final imagePath = product.imagen.replaceFirst('public/', 'storage/');
    // final imageUrl = '$baseUrl/$imagePath';
    candidates.add('$baseUrl/$imagePath');
    candidates.add('$baseUrl/$canonical');
    candidates.add('$baseUrl/$normalized');

    if (canonical.startsWith('public/')) {
      candidates.add('$baseUrl/${canonical.replaceFirst('public/', 'storage/')}');
      candidates.add('$baseUrl/${canonical.replaceFirst('public/', '')}');
    }

    if (canonical.startsWith('storage/')) {
      candidates.add('$baseUrl/$canonical');
      candidates.add('$baseUrl/${canonical.replaceFirst('storage/', 'public/')}');
    }

    candidates.add('$baseUrl/storage/img/$fileName');
    candidates.add('$baseUrl/public/img/$fileName');
    candidates.add('$baseUrl/img/$fileName');
    return candidates.toList(growable: false);
  }
}
