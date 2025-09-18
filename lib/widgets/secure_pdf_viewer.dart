import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SecurePdfViewer extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const SecurePdfViewer({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  State<SecurePdfViewer> createState() => _SecurePdfViewerState();
}

class _SecurePdfViewerState extends State<SecurePdfViewer> {
  String? localPath;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;
  bool isReady = false;
  String errorMessagePDF = '';

  @override
  void initState() {
    super.initState();
    _loadPdf();
    _preventScreenshots();
  }

  @override
  void dispose() {
    _cleanupTempFile();
    super.dispose();
  }

  // Prevent screenshots and screen recording
  void _preventScreenshots() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });

      // Download PDF to temporary file
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.fileName}.pdf');

        await tempFile.writeAsBytes(bytes);

        setState(() {
          localPath = tempFile.path;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'فشل في تحميل الملف: $e';
      });
    }
  }

  Future<void> _cleanupTempFile() async {
    if (localPath != null) {
      try {
        final file = File(localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error cleaning up temp file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.fileName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (isReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A84FF)),
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الملف...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'حدث خطأ غير متوقع',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPdf,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (localPath == null) {
      return const Center(
        child: Text(
          'لم يتم العثور على الملف',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return PDFView(
      filePath: localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      onRender: (pages) {
        setState(() {
          totalPages = pages ?? 0;
          isReady = true;
        });
      },
      onViewCreated: (PDFViewController pdfViewController) {
        // PDF viewer is ready
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          currentPage = page ?? 0;
        });
      },
      onError: (error) {
        setState(() {
          hasError = true;
          errorMessage = 'خطأ في عرض الملف: $error';
        });
      },
      onPageError: (page, error) {
        setState(() {
          hasError = true;
          errorMessage = 'خطأ في الصفحة $page: $error';
        });
      },
    );
  }
}
