import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../widgets/gradient_bg.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _ensureHttpUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: mode);
        return ok;
      }
      return false;
    } catch (e) {
      print('Launch error ($mode): $e');
      return false;
    }
  }

  Future<void> _openInExternalBrowser(String url) async {
    final normalized = _ensureHttpUrl(url);
    final uri = Uri.parse(normalized);

    // 1) Try external browser (chooser if no default)
    final openedExternal =
        await _tryLaunch(uri, LaunchMode.externalApplication);
    if (openedExternal) return;

    // 2) Fallback to in-app browser view
    final openedInApp = await _tryLaunch(uri, LaunchMode.inAppBrowserView);
    if (openedInApp) return;

    // 3) Final fallback: copy link and show message
    await Clipboard.setData(ClipboardData(text: normalized));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content:
            const Text('لا يمكن فتح رابط الدفع. تم نسخ الرابط إلى الحافظة'),
        action: SnackBarAction(
          label: 'فتح',
          onPressed: () async {
            await _tryLaunch(uri, LaunchMode.externalApplication);
          },
        ),
      ),
    );
  }

  Future<void> _showOpenOptions(String url) async {
    final normalized = _ensureHttpUrl(url);
    final uri = Uri.parse(normalized);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _tryLaunch(uri, LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('فتح في المتصفح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _tryLaunch(uri, LaunchMode.inAppBrowserView);
                  },
                  icon: const Icon(Icons.web_asset),
                  label: const Text('فتح داخل التطبيق'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: normalized));
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الرابط')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('نسخ الرابط'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final checkoutUrl = extra?['url'] as String?;

    print('Payment screen - Extra data: $extra');
    print('Payment screen - Checkout URL: $checkoutUrl');

    if (checkoutUrl == null) {
      return GradientDecoratedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'خطأ في الدفع',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'خطأ في تحميل صفحة الدفع',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى المحاولة مرة أخرى',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove the back button
          title: null, // Remove the title
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                24, 40, 24, 24), // Reduced top padding
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Changed from center to start
              children: [
                const SizedBox(height: 60), // Add space to push content up
                const Icon(
                  Icons.payment,
                  color: Color(0xFF0A84FF),
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'الدفع الآمن',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'انقر على الزر أدناه لفتح صفحة الدفع الآمنة في المتصفح',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _showOpenOptions(checkoutUrl),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('فتح صفحة الدفع'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'معلومات الدفع:',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'سيتم فتح صفحة دفع آمنة من Stripe',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'بعد إتمام الدفع، سيتم تفعيل حسابك تلقائياً',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF0A84FF),
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ملحوظة:',
                              style: TextStyle(
                                color: Color(0xFF0A84FF),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '1- تم تسجيل بياناتك بشكل مؤقت وفي حالة عدم إتمام الدفع في خلال 24 ساعة سيتم حذف البيانات',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '2- تم إرسال رابط دفع لحساب الجيميل المسجل في حالة إغلاق هذه الصفحة',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
