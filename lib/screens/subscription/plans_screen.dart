import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/gradient_bg.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final plans = await authProvider.getPlans();

    if (mounted) {
      setState(() {
        _plans = plans.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPlan(Map<String, dynamic> plan) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Create checkout session
    final checkoutUrl = await authProvider.createCheckoutSession(plan['id']);

    if (checkoutUrl != null && mounted) {
      // Navigate to payment screen with checkout URL
      context.go('/payment', extra: {'url': checkoutUrl});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'حدث خطأ في إنشاء جلسة الدفع'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go('/signup'),
          ),
          title: const Text(
            'اختر خطة الاشتراك',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  const Text(
                    'اختر الخطة المناسبة لك',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'جميع الخطط تشمل وصول كامل للمحتوى والدعم الفني',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Plans List
                  if (_plans.isNotEmpty)
                    ..._plans.map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: PlanCard(
                            plan: plan,
                            isSelected: false,
                            onTap: () => _selectPlan(plan),
                          ),
                        ))
                  else if (!_isLoading)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.grey[400],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد خطط متاحة حالياً',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadPlans,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Back Button
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: Text(
                      'العودة لتسجيل البيانات',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
