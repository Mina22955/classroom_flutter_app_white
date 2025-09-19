import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_info_row.dart';
import '../widgets/gradient_bg.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Helper method to safely get boolean value
  bool _getBoolValue(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return true; // default to true
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? {};

    final Map<String, dynamic> student = {
      'name': (user['name'] ?? user['fullName'] ?? '').toString(),
      'phone': (user['phone'] ?? user['mobile'] ?? '').toString(),
      'email': (user['email'] ?? '').toString(),
      'active': _getBoolValue(user['active'] ?? user['isActive'] ?? true),
      'renewal': (user['renewal'] ?? user['renewalDate'] ?? '').toString(),
    };

    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), // Light blue background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFF1565C0), // Darker blue for better contrast
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1565C0).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0A84FF), // brand blue
                                    Color(0xFF007AFF), // darker blue
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Student Name
                      Text(
                        student['name'],
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: student['active']
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                student['active'] ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: student['active']
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              student['active'] ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                color: student['active']
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Profile Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), // Light blue background
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معلومات الحساب',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ProfileInfoRow(
                        label: '', // Empty label
                        value: student['name'],
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      ProfileInfoRow(
                        label: '', // Empty label
                        value: student['phone'],
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 16),
                      ProfileInfoRow(
                        label: '', // Empty label
                        value: student['email'],
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      ProfileInfoRow(
                        label: '', // Empty label
                        value: student['renewal'],
                        icon: Icons.calendar_today_outlined,
                        valueColor: const Color(0xFFB0B0B0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Subscription plan card
                Builder(
                  builder: (context) {
                    // Use SubscriptionProvider if available
                    Map<String, dynamic>? selectedPlan;
                    try {
                      // ignore: use_build_context_synchronously
                      selectedPlan =
                          ModalRoute.of(context) != null ? null : null;
                    } catch (_) {}

                    // Use plan from user if available, else selectedPlan, else fallback
                    Map<String, dynamic>? userPlan;
                    try {
                      // Check if user['plan'] is a Map, if not, it might be a String ID
                      if (user['plan'] is Map<String, dynamic>) {
                        userPlan = user['plan'] as Map<String, dynamic>;
                      } else if (user['subscription'] is Map<String, dynamic>) {
                        userPlan = user['subscription'] as Map<String, dynamic>;
                      }
                    } catch (e) {
                      // If there's any error, set to null
                      userPlan = null;
                    }
                    final plan = userPlan ??
                        selectedPlan ??
                        {
                          'title': 'الخطة الشهرية',
                          'price': 29,
                          'currency': '\$',
                          'duration': 'شهر',
                        };

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD), // Light blue background
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon at top-left
                          const Align(
                            alignment: Alignment.topLeft,
                            child: Icon(
                              Icons.workspace_premium,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'الخطة الحالية',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (plan['title'] ?? plan['name'] ?? '').toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${plan['price'] ?? ''} ${plan['currency'] ?? '\$'} / ${(plan['duration'] ?? plan['durationText'] ?? '')}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Transparent button with blue outline and gradient text at bottom-left
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // TODO: Navigate to upgrade flow
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF0A84FF),
                                        width: 1.5),
                                  ),
                                  child: Center(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFF0A84FF),
                                          Color(0xFF007AFF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      blendMode: BlendMode.srcIn,
                                      child: const Text(
                                        'ترقيه الخطه',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Logout Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E3E).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          _showLogoutConfirmation(context, authProvider),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'تسجيل خروج',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Edit Profile Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF0A84FF), width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        // Simple edit dialog for demo
                        final nameController =
                            TextEditingController(text: student['name']);
                        final phoneController =
                            TextEditingController(text: student['phone']);
                        await showDialog(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF1C1C1E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Text('تعديل الملف الشخصي',
                                  style: TextStyle(color: Colors.white)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'الاسم',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: phoneController,
                                    decoration: const InputDecoration(
                                      hintText: 'رقم الهاتف',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final newName = nameController.text.trim();
                                    final newPhone =
                                        phoneController.text.trim();
                                    await Provider.of<AuthProvider>(context,
                                            listen: false)
                                        .updateProfile(
                                            name: newName.isEmpty
                                                ? null
                                                : newName,
                                            phone: newPhone.isEmpty
                                                ? null
                                                : newPhone);
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(ctx).pop();
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم حفظ التعديلات بنجاح'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  child: const Text('حفظ'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: const Text(
                            'تعديل الملف الشخصي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تأكيد تسجيل الخروج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: const Text(
              'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    // Close confirmation dialog first
                    Navigator.of(context).pop();

                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: const Color(0xFF1C1C1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xFFE53E3E),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'جاري تسجيل الخروج...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'يرجى الانتظار',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    // Perform logout process with immediate execution
                    print('ProfileScreen: Starting immediate logout...');

                    // Store user data before clearing for server logout
                    final userData = authProvider.user;
                    final deviceToken = authProvider.deviceToken;

                    // Clear local state immediately
                    await authProvider.quickLogout();

                    // Close loading dialog immediately
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }

                    // Navigate to login immediately
                    if (context.mounted) {
                      print('ProfileScreen: Navigating to login immediately');
                      context.go('/login');
                    }

                    // Try server logout in background (don't wait for it)
                    if (userData != null && deviceToken != null) {
                      Future.microtask(() async {
                        try {
                          print(
                              'ProfileScreen: Attempting background server logout...');
                          final apiService = ApiService();
                          await apiService.logout(
                            userId: userData['id'] ?? userData['_id'],
                            deviceToken: deviceToken,
                          );
                          print(
                              'ProfileScreen: Background server logout completed');
                        } catch (e) {
                          print(
                              'ProfileScreen: Background server logout failed: $e');
                        }
                      });
                    }
                  },
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
