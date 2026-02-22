import 'package:flutter/material.dart';
import 'package:larpland/service/api_config.dart';
import 'package:larpland/service/auth_session.dart';

class SmartNetworkImage extends StatefulWidget {
  final String imagePath;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SmartNetworkImage({
    super.key,
    required this.imagePath,
    required this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<SmartNetworkImage> createState() => _SmartNetworkImageState();
}

class _SmartNetworkImageState extends State<SmartNetworkImage> {
  late List<String> _candidates;
  int _index = 0;
  bool _useAuthHeader = false;

  @override
  void initState() {
    super.initState();
    _resetCandidates();
  }

  @override
  void didUpdateWidget(covariant SmartNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resetCandidates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCandidates = _candidates.isNotEmpty;
    final currentUrl = hasCandidates ? _candidates[_index] : null;

    Widget child;
    if (currentUrl == null) {
      child = _broken();
    } else {
      final token = AuthSession.token;
      final hasToken = token != null && token.isNotEmpty;
      final headers = _useAuthHeader && hasToken
          ? <String, String>{'Authorization': 'Bearer $token'}
          : null;

      child = SizedBox(
        height: widget.height,
        width: widget.width ?? double.infinity,
        child: Image.network(
          currentUrl,
          headers: headers,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          fit: widget.fit,
          width: widget.width ?? double.infinity,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) {
            if (_index < _candidates.length - 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _index += 1;
                });
              });
              return SizedBox(
                height: widget.height,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            // Web commonly blocks image requests with custom auth headers (CORS).
            // Try all candidates without headers first, then retry with auth.
            if (!_useAuthHeader && hasToken) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _useAuthHeader = true;
                  _index = 0;
                });
              });
              return SizedBox(
                height: widget.height,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            return _broken();
          },
        ),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }
    return child;
  }

  void _resetCandidates() {
    _candidates = ApiConfig.resolveImageCandidates(widget.imagePath);
    _index = 0;
    _useAuthHeader = false;
  }

  Widget _broken() {
    return SizedBox(
      height: widget.height,
      width: widget.width ?? double.infinity,
      child: const Center(
        child: Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
