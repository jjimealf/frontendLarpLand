class ApiConfig {
  // Conservado por compatibilidad con el resto del proyecto.
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

  static String resolveImageUrl(String rawPath) {
    final urls = resolveImageCandidates(rawPath);
    return urls.isEmpty ? '' : urls.first;
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
    final candidates = <String>{canonical, normalized};
    if (baseUrl.isNotEmpty) {
      candidates.add('$baseUrl/$canonical');
      candidates.add('$baseUrl/$normalized');
    }
    return candidates.toList(growable: false);
  }
}
