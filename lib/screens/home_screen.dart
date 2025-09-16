import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  final List<Map<String, String>> _joinedClasses = [];
  bool _isJoiningClass = false;

  @override
  void initState() {
    super.initState();
    // Rebuild to show/ hide clear icon and enable button
    _classIdController.addListener(() {
      if (mounted) setState(() {});
    });
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
          // avoid duplicates
          final exists = _joinedClasses.any((c) => c['id'] == classId);
          if (!exists) {
            _joinedClasses.add({'id': classId, 'name': className});
          }
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

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
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
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: GradientDecoratedBackground(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Student top card
                      StudentCard(
                        studentName: user?['name'] ?? 'الطالب',
                        isSubscribed: true,
                        renewalDate: '2025-12-31',
                        onTap: () => context.push('/profile'),
                      ),
                      const SizedBox(height: 20),
                      // Input and Join button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 54,
                                child: TextField(
                                  controller: _classIdController,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    hintText: 'أدخل رقم الكلاس',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.black.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.black.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0A84FF),
                                        width: 1.5,
                                      ),
                                    ),
                                    prefixIcon: const Icon(Icons.class_,
                                        color: Color(0xFF0A84FF)),
                                    suffixIcon:
                                        _classIdController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear,
                                                    color: Colors.grey),
                                                onPressed: () {
                                                  _classIdController.clear();
                                                },
                                              )
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              height: 54,
                              child: CustomButton(
                                text: _isJoiningClass ? 'جارٍ الدخول' : 'دخول',
                                onPressed:
                                    _classIdController.text.trim().isEmpty
                                        ? null
                                        : _handleJoinClass,
                                isLoading: _isJoiningClass,
                                backgroundGradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0A84FF),
                                    Color(0xFF007AFF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                height: 54,
                                width: 120,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'الكلاسات المنضَمّة',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _joinedClasses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final klass = _joinedClasses[index];
                            return ClassCard(
                              className: klass['name']!,
                              onTap: () => context.push(
                                '/classroom',
                                extra: {
                                  'id': klass['id'],
                                  'name': klass['name'],
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
