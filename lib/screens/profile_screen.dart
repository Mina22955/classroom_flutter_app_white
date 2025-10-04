import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_info_row.dart';
import '../widgets/gradient_bg.dart';
import '../widgets/countdown_timer.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _planDetails;
  bool _isLoadingPlan = false;

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  // Glass-styled snackbar helper to unify success/error toasts
  void _showGlassSnackBar(
    BuildContext context, {
    required String message,
    required Color color,
    IconData icon = Icons.info_outline,
  }) {
    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  // Reusable glass-styled container with enhanced borders and decorations
  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BorderRadiusGeometry borderRadius =
        const BorderRadius.all(Radius.circular(20)),
    double borderWidth = 2.5,
    bool showDecorations = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: const Color(0xFF1976D2), // Outer border
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Clear and distinct card with enhanced border and shadows
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // White background
                borderRadius: borderRadius,
                border: Border.all(
                  color: const Color(0xFF1976D2), // Inner border
                  width: 1,
                ),
              ),
            ),
            // Inner glass layer with enhanced border
            Container(
              margin: EdgeInsets.all(borderWidth),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.85), // More opaque for better clarity
                borderRadius: BorderRadius.circular(
                  (borderRadius is BorderRadius) ? borderRadius.topLeft.x : 20,
                ),
                border: Border.all(
                  color: const Color(0xFF1976D2)
                      .withOpacity(0.2), // Subtle inner border
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Stack(
                  children: [
                    // Decorative elements
                    if (showDecorations) ...[
                      // Top-right graduation cap
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF).withOpacity(0.005),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Color(0xFF0A84FF),
                            size: 14,
                          ),
                        ),
                      ),
                      // Bottom-left blue star
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF).withOpacity(0.005),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Color(0xFF0A84FF),
                            size: 14,
                          ),
                        ),
                      ),
                      // Top-left small blue star
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withOpacity(0.005),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.star_border,
                            color: Color(0xFF007AFF),
                            size: 12,
                          ),
                        ),
                      ),
                      // Bottom-right small blue star
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF).withOpacity(0.005),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Color(0xFF0A84FF),
                            size: 12,
                          ),
                        ),
                      ),
                      // Center-right small graduation cap
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withOpacity(0.005),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF007AFF),
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                    // Main content
                    Padding(
                      padding: padding,
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section heading with decorative underline
  Widget _sectionHeading(String title,
      {IconData? icon, Color color = const Color(0xFF1A1A1A)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF0A84FF),
              ),
            if (icon != null) const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // Subtle divider used between info rows
  Widget _softDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.04),
            Colors.black.withOpacity(0.08),
            Colors.black.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // Removed automatic refresh on visibility to avoid repeated requests

  // (Removed unused _refreshPlanDetails to satisfy linter)

  Future<void> _loadPlanDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isLoadingPlan = true;
    });
    try {
      final cached = await authProvider.getCachedCurrentPlanDetails();
      if (!mounted) return;
      setState(() {
        _planDetails = cached;
        _isLoadingPlan = false;
      });
    } catch (e) {
      print('ProfileScreen: Error loading plan details via provider: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingPlan = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Get fresh student data from unified API
      final studentData = await authProvider.getFreshStudentData();

      if (studentData != null) {
        // Update plan details from the fresh data
        if (studentData['plan'] != null) {
          setState(() {
            _planDetails = studentData['plan'];
            _isLoadingPlan = false;
          });
        }

        if (mounted) {
          _showGlassSnackBar(
            context,
            message: 'تم تحديث البيانات بنجاح',
            color: const Color(0xFF22C55E),
            icon: Icons.check_circle_outline,
          );
        }
      } else {
        if (mounted) {
          _showGlassSnackBar(
            context,
            message: 'فشل في تحديث البيانات',
            color: const Color(0xFFEF4444),
            icon: Icons.error_outline,
          );
        }
      }
    } catch (e) {
      print('ProfileScreen: Error refreshing data: $e');
      if (mounted) {
        _showGlassSnackBar(
          context,
          message: 'فشل في تحديث البيانات: $e',
          color: const Color(0xFFEF4444),
          icon: Icons.error_outline,
        );
      }
    }
  }

  // Helper method to safely get boolean value
  bool _getBoolValue(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return true; // default to true
  }

  DateTime? _parseExpiryDate(dynamic expiresAt) {
    if (expiresAt == null) return null;

    try {
      if (expiresAt is String) {
        return DateTime.parse(expiresAt);
      } else if (expiresAt is int) {
        // Unix timestamp in seconds
        return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      } else {
        // Unix timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(expiresAt);
      }
    } catch (e) {
      print('Error parsing expiry date: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? {};

    // Debug: Print user data to see what we're getting
    print('ProfileScreen: User data: $user');
    print('ProfileScreen: Phone field: ${user['phone']}');
    print('ProfileScreen: Mobile field: ${user['mobile']}');

    final Map<String, dynamic> student = {
      'name': (user['name'] ?? user['fullName'] ?? 'غير محدد').toString(),
      'phone': (user['phone'] ?? user['mobile'] ?? 'غير محدد').toString(),
      'email': (user['email'] ?? 'غير محدد').toString(),
      'active': _getBoolValue(
          user['active'] ?? user['isActive'] ?? user['status'] == 'active'),
      'expiresAt': user['expiresAt'],
    };

    print('ProfileScreen: Processed student data: $student');

    final expiryDate = _parseExpiryDate(student['expiresAt']);

    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
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
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFF0A84FF),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header Card with Account Info
                    _glassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF86B6FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
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
                                        Color(0xFF0A84FF),
                                        Color(0xFF007AFF)
                                      ],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: const Icon(Icons.person,
                                      size: 38, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Student Name
                          Text(
                            student['name'],
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 4,
                            width: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                              ),
                              borderRadius: BorderRadius.circular(4),
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
                                color: student['active']
                                    ? Colors.green
                                    : Colors.red,
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
                          const SizedBox(height: 20),
                          // Account Information Section
                          _glassContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeading('معلومات الحساب',
                                    icon: Icons.info_outline),
                                const SizedBox(height: 12),
                                ProfileInfoRow(
                                  label: '',
                                  value: student['name'],
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 10),
                                _softDivider(),
                                const SizedBox(height: 10),
                                ProfileInfoRow(
                                  label: '',
                                  value: student['phone'],
                                  icon: Icons.phone_outlined,
                                ),
                                const SizedBox(height: 10),
                                _softDivider(),
                                const SizedBox(height: 10),
                                ProfileInfoRow(
                                  label: '',
                                  value: student['email'],
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 10),
                                _softDivider(),
                                const SizedBox(height: 10),
                                ProfileInfoRow(
                                  label: '',
                                  value: expiryDate != null
                                      ? '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}'
                                      : 'غير محدد',
                                  icon: Icons.calendar_today_outlined,
                                  valueColor: const Color(0xFFB0B0B0),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Countdown Timer with enhanced styling
                    if (expiryDate != null)
                      _glassContainer(
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text on the right (first child in RTL)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'الوقت المتبقي على الاشتراك',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CountdownTimer(
                                    expiryDate: expiryDate,
                                    onExpired: () {},
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0A84FF),
                                    Color(0xFF007AFF)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.timer_outlined,
                                  color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Subscription plan card
                    _glassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(16),
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
                          _sectionHeading('الخطة الحالية',
                              icon: Icons.workspace_premium),
                          const SizedBox(height: 12),
                          if (_isLoadingPlan)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0A84FF),
                              ),
                            )
                          else if (_planDetails != null) ...[
                            Text(
                              _planDetails!['title'] ?? 'خطة غير محددة',
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_planDetails!['price'] ?? 0} جنيه / ${_planDetails!['durationValue'] ?? 1} ${_planDetails!['durationType'] == 'month' ? 'شهر' : 'سنة'}',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                            if (_planDetails!['description'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _planDetails!['description'],
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ] else ...[
                            const Text(
                              'خطة غير محددة',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'لا توجد خطة نشطة',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Enhanced button with blue outline and gradient text at bottom-left
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _showUpgradeConfirmation(context);
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
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0A84FF)
                                            .withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Decorative blue star in top-right corner
                                      Positioned(
                                        top: 2,
                                        right: 4,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.005),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: Color(0xFF0A84FF),
                                            size: 8,
                                          ),
                                        ),
                                      ),
                                      // Main content
                                      Center(
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Edit Profile Button with enhanced styling
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF0A84FF), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A84FF).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showEditProfileDialog(context, student),
                          child: Stack(
                            children: [
                              // Decorative blue star in top-right corner
                              Positioned(
                                top: 4,
                                right: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A84FF)
                                        .withOpacity(0.005),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Color(0xFF0A84FF),
                                    size: 10,
                                  ),
                                ),
                              ),
                              // Main content
                              Center(
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
                                    'تعديل الملف الشخصي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logout Button with enhanced styling
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE53E3E), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.1),
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
                          child: Stack(
                            children: [
                              // Decorative graduation cap in top-left corner
                              Positioned(
                                top: 4,
                                left: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53E3E)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    color: Color(0xFFE53E3E),
                                    size: 10,
                                  ),
                                ),
                              ),
                              // Main content
                              Center(
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [
                                      Color(0xFFE53E3E),
                                      Color(0xFFC53030)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: const Text(
                                    'تسجيل خروج',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, Map<String, dynamic> student) {
    final nameController = TextEditingController(
        text: student['name'] == 'غير محدد' ? '' : student['name']);
    final phoneController = TextEditingController(
        text: student['phone'] == 'غير محدد' ? '' : student['phone']);
    final emailController = TextEditingController(
        text: student['email'] == 'غير محدد' ? '' : student['email']);
    final passwordController = TextEditingController();

    final scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            body: Center(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).size.height *
                                0.6 // Smaller when keyboard is open
                            : MediaQuery.of(context).size.height *
                                0.8, // Normal size when keyboard is closed
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0A84FF).withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header (glass style)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.35),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              border: Border.all(
                                color: const Color(0xFF0A84FF).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 149, 199, 248),
                                  Color(0xFF007AFF)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: const Text(
                                'تعديل الملف الشخصي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Form Content
                          Flexible(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: EdgeInsets.all(24).copyWith(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom > 0
                                        ? 16
                                        : 24,
                              ),
                              child: Column(
                                children: [
                                  // Name Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'الاسم',
                                      style: TextStyle(
                                        color: const Color(0xFF6B7280),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.transparent, width: 0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        hintText: 'الاسم',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Color(0xFF0A84FF),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.22),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 1.8,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom >
                                              0
                                          ? 12
                                          : 16),
                                  // Phone Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'رقم الهاتف',
                                      style: TextStyle(
                                        color: const Color(0xFF6B7280),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.transparent, width: 0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: 'رقم الهاتف',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.phone_outlined,
                                          color: Color(0xFF0A84FF),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.22),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 1.8,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom >
                                              0
                                          ? 12
                                          : 16),
                                  // Email Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'البريد الإلكتروني',
                                      style: TextStyle(
                                        color: const Color(0xFF6B7280),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.transparent, width: 0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: 'البريد الإلكتروني',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                          color: Color(0xFF0A84FF),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.22),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 1.8,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom >
                                              0
                                          ? 12
                                          : 16),
                                  // Password Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'كلمة المرور الجديدة (اختياري)',
                                      style: TextStyle(
                                        color: const Color(0xFF6B7280),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.transparent, width: 0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText:
                                            'كلمة المرور الجديدة (اختياري)',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          color: Color(0xFF0A84FF),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.22),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 1.8,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.45),
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom >
                                              0
                                          ? 16
                                          : 24),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      // Cancel Button
                                      Expanded(
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Center(
                                                child: Text(
                                                  'إلغاء',
                                                  style: TextStyle(
                                                    color: Color(0xFF6B7280),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Save Button
                                      Expanded(
                                        child: Consumer<AuthProvider>(
                                          builder:
                                              (context, authProvider, child) {
                                            return Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.25),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFF0A84FF),
                                                    width: 1.5),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  onTap: authProvider.isLoading
                                                      ? null
                                                      : () async {
                                                          final newName =
                                                              nameController
                                                                  .text
                                                                  .trim();
                                                          final newPhone =
                                                              phoneController
                                                                  .text
                                                                  .trim();
                                                          final newEmail =
                                                              emailController
                                                                  .text
                                                                  .trim();
                                                          final newPassword =
                                                              passwordController
                                                                  .text
                                                                  .trim();

                                                          if (newName.isEmpty ||
                                                              newPhone
                                                                  .isEmpty ||
                                                              newEmail
                                                                  .isEmpty) {
                                                            _showGlassSnackBar(
                                                              context,
                                                              message:
                                                                  'جميع الحقول مطلوبة',
                                                              color: const Color(
                                                                  0xFFEF4444),
                                                              icon: Icons
                                                                  .error_outline,
                                                            );
                                                            return;
                                                          }

                                                          final success =
                                                              await authProvider
                                                                  .updateProfile(
                                                            name: newName,
                                                            phone: newPhone,
                                                            email: newEmail,
                                                            password: newPassword
                                                                    .isNotEmpty
                                                                ? newPassword
                                                                : null,
                                                          );

                                                          if (success) {
                                                            Navigator.of(ctx)
                                                                .pop();
                                                            _showGlassSnackBar(
                                                              context,
                                                              message:
                                                                  'تم حفظ التعديلات بنجاح',
                                                              color: const Color(
                                                                  0xFF22C55E),
                                                              icon: Icons
                                                                  .check_circle_outline,
                                                            );
                                                          } else {
                                                            _showGlassSnackBar(
                                                              context,
                                                              message: authProvider
                                                                      .error ??
                                                                  'فشل في تحديث الملف الشخصي',
                                                              color: const Color(
                                                                  0xFFEF4444),
                                                              icon: Icons
                                                                  .error_outline,
                                                            );
                                                          }
                                                        },
                                                  child: Center(
                                                    child: authProvider
                                                            .isLoading
                                                        ? const SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color: Color(
                                                                  0xFF0A84FF),
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : ShaderMask(
                                                            shaderCallback:
                                                                (bounds) =>
                                                                    const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xFF0A84FF),
                                                                Color(
                                                                    0xFF007AFF)
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ).createShader(
                                                                        bounds),
                                                            blendMode:
                                                                BlendMode.srcIn,
                                                            child: const Text(
                                                              'حفظ',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUpgradeConfirmation(BuildContext context) {
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
              'تأكيد ترقية الخطة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: const Text(
              'في حالة الدخول لهذه الصفحة سيكون الحساب معلق لحين اتمام الدفع',
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
                    colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/plan-selection');
                  },
                  child: const Text(
                    'متابعة',
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

                    // Perform immediate logout without any loading dialogs
                    print(
                        'ProfileScreen: Starting immediate logout after confirmation...');

                    // Store user data before clearing for server logout
                    final userData = authProvider.user;
                    final deviceToken = authProvider.deviceToken;

                    // Clear local state immediately
                    await authProvider.quickLogout();

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
