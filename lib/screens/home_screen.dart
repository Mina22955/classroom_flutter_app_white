import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../widgets/student_card.dart';
import '../widgets/class_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/gradient_bg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _classIdController = TextEditingController();
  List<Map<String, dynamic>> _joinedClasses = [];
  bool _isJoiningClass = false;
  bool _joinExpanded = false;
  bool _isLoadingClasses = false;

  @override
  void initState() {
    super.initState();
    // Rebuild to show/ hide clear icon and enable button
    _classIdController.addListener(() {
      if (mounted) setState(() {});
    });
    // Load joined classes when screen initializes
    _loadJoinedClasses();
  }

  Future<void> _loadJoinedClasses() async {
    if (!mounted) return;

    print('Loading joined classes...');
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      print('HomeScreen: About to call getStudentClasses()');
      final classes = await authProvider.getStudentClasses();
      print('HomeScreen: Fetched classes from API: $classes');
      print('HomeScreen: Classes count: ${classes.length}');
      if (mounted) {
        setState(() {
          _joinedClasses = classes;
          _isLoadingClasses = false;
        });
        print('HomeScreen: Updated _joinedClasses: $_joinedClasses');
        print('HomeScreen: _joinedClasses length: ${_joinedClasses.length}');
      }
    } catch (e) {
      print('HomeScreen: Error loading classes: $e');
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _classIdController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinClass() async {
    final id = _classIdController.text.trim();
    if (id.isEmpty) return;

    setState(() {
      _isJoiningClass = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.joinClassById(id);
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        print('Join class successful, refreshing classes list...');

        setState(() {
          _isJoiningClass = false;
        });

        // Small delay to ensure backend has processed the join
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh the classes list from backend
        await _loadJoinedClasses();

        print(
            'Classes list refreshed, current count: ${_joinedClasses.length}');

        // If no classes were loaded from backend, add the joined class locally as fallback
        if (_joinedClasses.isEmpty) {
          print(
              'No classes from backend, adding joined class locally as fallback');
          final joined = result['class'];
          final classId = (joined is Map<String, dynamic>)
              ? (joined['id']?.toString() ?? joined['_id']?.toString() ?? id)
              : id;
          final className = (joined is Map<String, dynamic>)
              ? (joined['name']?.toString() ??
                  joined['title']?.toString() ??
                  'كلاس')
              : 'كلاس';

          setState(() {
            _joinedClasses.add({
              'id': classId,
              'name': className,
            });
          });
          print('Added fallback class: $className with ID: $classId');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
            ),
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF0A84FF)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم الانضمام إلى الكلاس بنجاح',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        _classIdController.clear();
      } else {
        setState(() {
          _isJoiningClass = false;
        });
        final error = authProvider.error ?? 'فشل في الانضمام إلى الكلاس';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoiningClass = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
          ),
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'حدث خطأ غير متوقع',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            body: Stack(
              children: [
                const GradientDecoratedBackground(child: SizedBox.expand()),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Student card with logout
                          _buildStudentCardWithLogout(
                            studentName: user?['name'] ?? 'الطالب',
                            isSubscribed: true,
                            renewalDate: '2025-12-31',
                            onProfileTap: () => context.push('/profile'),
                            onLogoutTap: () =>
                                _showLogoutConfirmation(context, authProvider),
                          ),
                          const SizedBox(height: 24),
                          // Collapsible Join control
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(anim);
                              return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                    position: slide, child: child),
                              );
                            },
                            child: !_joinExpanded
                                ? Container(
                                    key: const ValueKey('join_collapsed'),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0A84FF),
                                          Color(0xFF007AFF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0A84FF)
                                              .withOpacity(0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => setState(
                                            () => _joinExpanded = true),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          height: 64,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.group_add_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                'انضمام إلى كلاس',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    key: const ValueKey('join_expanded'),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF0F7FF),
                                          Colors.white
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.05),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                    colors: [
                                                      Color(0xFF0A84FF),
                                                      Color(0xFF007AFF)
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFF0A84FF)
                                                          .withOpacity(0.25),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                    Icons.group_add_rounded,
                                                    color: Colors.white,
                                                    size: 20),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'انضمام إلى كلاس',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                onPressed: () => setState(() =>
                                                    _joinExpanded = false),
                                                icon: const Icon(
                                                    Icons.close_rounded,
                                                    color: Color(0xFF6B7280)),
                                                tooltip: 'إغلاق',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 54,
                                                  child: TextField(
                                                    controller:
                                                        _classIdController,
                                                    textAlignVertical:
                                                        TextAlignVertical
                                                            .center,
                                                    decoration: InputDecoration(
                                                      filled: true,
                                                      fillColor: const Color(
                                                          0xFFF8FAFF),
                                                      hintText:
                                                          'أدخل رقم الكلاس',
                                                      hintStyle:
                                                          const TextStyle(
                                                        color:
                                                            Color(0xFF9CA3AF),
                                                        fontSize: 15,
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 14),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        borderSide: BorderSide(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.06),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        borderSide: BorderSide(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.06),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        borderSide:
                                                            const BorderSide(
                                                          color:
                                                              Color(0xFF0A84FF),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      prefixIcon: const Icon(
                                                          Icons.class_,
                                                          color: Color(
                                                              0xFF0A84FF)),
                                                      suffixIcon: SizedBox(
                                                        width: 92,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              tooltip: 'لصق',
                                                              icon: const Icon(
                                                                  Icons
                                                                      .paste_rounded,
                                                                  color: Color(
                                                                      0xFF6B7280)),
                                                              onPressed:
                                                                  () async {
                                                                final data =
                                                                    await Clipboard.getData(
                                                                        Clipboard
                                                                            .kTextPlain);
                                                                if (data?.text !=
                                                                    null) {
                                                                  _classIdController
                                                                          .text =
                                                                      data!
                                                                          .text!
                                                                          .trim();
                                                                  setState(
                                                                      () {});
                                                                }
                                                              },
                                                            ),
                                                            if (_classIdController
                                                                .text
                                                                .isNotEmpty)
                                                              IconButton(
                                                                tooltip: 'مسح',
                                                                icon: const Icon(
                                                                    Icons
                                                                        .clear_rounded,
                                                                    color: Color(
                                                                        0xFF9CA3AF)),
                                                                onPressed: () {
                                                                  _classIdController
                                                                      .clear();
                                                                  setState(
                                                                      () {});
                                                                },
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              SizedBox(
                                                height: 54,
                                                width: 132,
                                                child: CustomButton(
                                                  text: _isJoiningClass
                                                      ? 'جارٍ الانضمام'
                                                      : 'انضمام',
                                                  onPressed: _classIdController
                                                          .text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : _handleJoinClass,
                                                  isLoading: _isJoiningClass,
                                                  backgroundGradient:
                                                      const LinearGradient(
                                                    colors: [
                                                      Color(0xFF0A84FF),
                                                      Color(0xFF007AFF)
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: const [
                                              Icon(Icons.info_outline_rounded,
                                                  size: 16,
                                                  color: Color(0xFF6B7280)),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'أدخل رقم الكلاس للانضمام إليه',
                                                  style: TextStyle(
                                                    color: Color(0xFF6B7280),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text(
                                'الكلاسات المنضَمّة',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _loadJoinedClasses,
                                icon: const Icon(Icons.refresh,
                                    color: Color(0xFF0A84FF)),
                                tooltip: 'تحديث القائمة',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _isLoadingClasses
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0A84FF),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadJoinedClasses,
                                    color: const Color(0xFF0A84FF),
                                    child: ListView.separated(
                                      itemCount: _joinedClasses.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final klass = _joinedClasses[index];
                                        return ClassCard(
                                          className:
                                              klass['name']?.toString() ??
                                                  'كلاس',
                                          onTap: () => context.push(
                                            '/classroom',
                                            extra: {
                                              'id':
                                                  klass['id']?.toString() ?? '',
                                              'name':
                                                  klass['name']?.toString() ??
                                                      'كلاس',
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          // Empty state for joined classes
                          if (!_isLoadingClasses && _joinedClasses.isEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 40),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'لم تنضم إلى أي كلاس بعد',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'استخدم زر "انضمام إلى كلاس" لإضافة كلاس جديد',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
        );
      },
    );
  }

  Widget _buildStudentCardWithLogout({
    required String studentName,
    required bool isSubscribed,
    required String renewalDate,
    required VoidCallback onProfileTap,
    required VoidCallback onLogoutTap,
  }) {
    return Container(
      height: 130, // Fixed height to prevent overlapping
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative ring
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0A84FF).withOpacity(0.15),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Status badge
            Positioned(
              bottom: 20,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isSubscribed ? Colors.green : Colors.red)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isSubscribed ? Colors.green : Colors.red)
                        .withOpacity(0.6),
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
                        color: isSubscribed ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSubscribed ? 'نشط' : 'غير مفعل',
                      style: TextStyle(
                        color:
                            isSubscribed ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Logout button
            Positioned(
              top: 16,
              left: 16,
              child: InkWell(
                onTap: onLogoutTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A84FF).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            // Clickable left half for profile
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onProfileTap,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: Container(
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right half (non-clickable)
                  Expanded(
                    child: Container(
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            // User name at top right
            Positioned(
              top: 20,
              right: 16,
              child: Text(
                studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Renewal date at bottom
            Positioned(
              bottom: 20,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    'تجديد: $renewalDate',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                    colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
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
