import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/gradient_bg.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedPlan;

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
        _plans = plans;
        _isLoading = false;
      });
    }
  }

  void _selectPlan(Map<String, dynamic> plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  void _proceedToSignup() {
    if (_selectedPlan != null) {
      context.go('/signup', extra: {'plan': _selectedPlan});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار خطة اشتراك'),
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
            onPressed: () => context.go('/login'),
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
            child: Column(
              children: [
                Expanded(
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
                                  isSelected:
                                      _selectedPlan?['_id'] == plan['_id'],
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
                      ],
                    ),
                  ),
                ),

                // Bottom section with selected plan info and proceed button
                if (_selectedPlan != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(
                            color: Colors.black.withOpacity(0.06), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPlan!['title'] ?? 'خطة غير محددة',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_selectedPlan!['price'] ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _proceedToSignup,
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
                          child: const Text('متابعة التسجيل'),
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
