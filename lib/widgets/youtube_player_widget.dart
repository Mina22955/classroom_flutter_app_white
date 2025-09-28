import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;
  final String title;
  final bool autoPlay;
  final bool showControls;
  final double aspectRatio;

  const YoutubePlayerWidget({
    Key? key,
    required this.videoId,
    required this.title,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
  }) : super(key: key);

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_getEmbedUrl()));
  }

  String _getEmbedUrl() {
    return 'https://www.youtube.com/embed/${widget.videoId}?autoplay=${widget.autoPlay ? 1 : 0}&rel=0&modestbranding=1&controls=${widget.showControls ? 1 : 0}';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if videoId is valid
    if (widget.videoId.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'فيديو غير متوفر',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading)
              Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class YoutubePlayerFullscreen extends StatefulWidget {
  final String videoId;
  final String title;

  const YoutubePlayerFullscreen({
    Key? key,
    required this.videoId,
    required this.title,
  }) : super(key: key);

  @override
  State<YoutubePlayerFullscreen> createState() =>
      _YoutubePlayerFullscreenState();
}

class _YoutubePlayerFullscreenState extends State<YoutubePlayerFullscreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_getEmbedUrl()));
  }

  String _getEmbedUrl() {
    return 'https://www.youtube.com/embed/${widget.videoId}?autoplay=1&rel=0&modestbranding=1&controls=1';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.videoId.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'فيديو غير متوفر',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            )
          : Center(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
