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

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _joinedClasses.add({
        'id': id,
        'name': 'كلاس رقم $id',
      });
      _isJoiningClass = false;
    });

    _classIdController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
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
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.logout,
                        color: Colors.black,
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
                            child: SizedBox(
                              height: 52,
                              child: TextField(
                                controller: _classIdController,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText: 'ID الكلاس',
                                  filled: true,
                                  fillColor: const Color(0xFFF2F2F7),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.black.withOpacity(0.12),
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
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            child: CustomButton(
                              text: 'دخول',
                              onPressed: _handleJoinClass,
                              isLoading: _isJoiningClass,
                              backgroundGradient: const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              height: 52,
                              width: 100,
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
