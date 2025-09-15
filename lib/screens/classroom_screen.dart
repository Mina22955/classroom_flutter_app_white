import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/note_card.dart';
import '../widgets/gradient_bg.dart';
import '../services/api_service.dart';

class ClassroomScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ClassroomScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  // Default section: ملاحظات
  int _currentIndex = 0;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _videos = [];
  bool _isLoadingVideos = false;
  // Notes filter: 0=All, 1=Last day, 2=Last week, 3=Last month
  int _notesFilter = 0;

  // Track expansion state for video and exam cards
  final Map<String, bool> _expandedStates = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoadingVideos = true);
    try {
      final videos = await _apiService.listVideos(classId: widget.classId);
      setState(() => _videos = videos);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoadingVideos = false);
    }
  }

  // Build filtered items for current section based on the search query
  Widget _buildCurrentSectionList() {
    final String q = _searchController.text.trim();

    List<Map<String, dynamic>> items;
    if (_currentIndex == 0) {
      // الملاحظات (حائط ملاحظات - قراءة فقط)
      items = [
        {
          'title': 'ملاحظة طويلة للاختبار',
          'content':
              'هذه ملاحظة تجريبية طويلة للتأكد من أن التصميم يتعامل مع النصوص الكبيرة بشكل صحيح. نريد أن نرى كيف يتم الالتفاف داخل الفقاعة والمحاذاة في الاتجاه من اليمين إلى اليسار. كذلك يجب التأكد من أن المسافات والسطور بين الجمل تبدو مريحة للقراءة ولا تخرج عن الحدود. في حال زاد طول النص كثيراً، ينبغي أن يواصل السطر التالي داخل نفس الفقاعة بدون كسر غير مرغوب. وأخيراً، نتأكد أن الأيقونة والزمن يبقيان في مكانهما بشكل سليم.',
          'timestamp': '14:30 2025-09-10'
        },
        {
          'title': 'ملاحظة من المعلم',
          'content': 'أحسنتم في واجب الدرس الماضي. الرجاء مراجعة سؤال 3 جيداً.',
          'timestamp': '10:30 2025-09-10'
        },
        {
          'title': 'تنبيه',
          'content':
              'سيتم إجراء اختبار قصير في الحصة القادمة على الوحدة الأولى.',
          'timestamp': '12:15 2025-09-10'
        },
        {
          'title': 'مراجعة',
          'content': 'اقرأ الملخص المرفق في الملفات قبل مشاهدة الفيديو التالي.',
          'timestamp': '13:05 2025-09-10'
        },
      ];

      // Sort: newest first (timestamp format: HH:mm yyyy-MM-dd)
      int parseTwo(String s) => int.tryParse(s) ?? 0;
      DateTime parseTs(String? ts) {
        if (ts == null) return DateTime.fromMillisecondsSinceEpoch(0);
        try {
          final parts = ts.split(' '); // [HH:mm, yyyy-MM-dd]
          if (parts.length != 2) return DateTime.fromMillisecondsSinceEpoch(0);
          final time = parts[0].split(':');
          final date = parts[1].split('-');
          if (time.length != 2 || date.length != 3) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
          final hour = parseTwo(time[0]);
          final minute = parseTwo(time[1]);
          final year = int.tryParse(date[0]) ?? 1970;
          final month = parseTwo(date[1]);
          final day = parseTwo(date[2]);
          return DateTime(year, month, day, hour, minute);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }

      // Apply time filter
      DateTime now = DateTime.now();
      Duration window;
      if (_notesFilter == 1) {
        window = const Duration(days: 1);
      } else if (_notesFilter == 2) {
        window = const Duration(days: 7);
      } else if (_notesFilter == 3) {
        window = const Duration(days: 30);
      } else {
        window = Duration.zero; // all
      }

      if (window != Duration.zero) {
        final cutoff = now.subtract(window);
        items = items
            .where((m) => parseTs(m['timestamp'] as String?).isAfter(cutoff))
            .toList();
      }

      items.sort((a, b) {
        final ta = parseTs(a['timestamp'] as String?);
        final tb = parseTs(b['timestamp'] as String?);
        return tb.compareTo(ta); // newest first
      });
    } else if (_currentIndex == 1) {
      // الملفات
      items = List.generate(
          6,
          (i) => {
                'title': 'ملف رقم ${i + 1}',
                'content': 'تفاصيل الملف والوصف المختصر.',
                'file': 'material_${i + 1}.pdf',
              });
    } else if (_currentIndex == 2) {
      // الفيديوهات: استخدام البيانات من API
      if (_isLoadingVideos) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }
      items = _videos
          .map((video) => {
                'id': video['id'],
                'title': video['title'],
                'content':
                    'مدة الفيديو: ${_formatDuration(video['durationSec'] ?? 0)}',
                'url': video['url'],
              })
          .toList();
    } else {
      // الامتحانات: كل عنصر يحتوي أيضاً على اسم ملف PDF افتراضي وموعد نهائي
      items = List.generate(
        3,
        (i) => {
          'title': 'امتحان الوحدة ${i + 1}',
          'content': 'تعليمات عامة ووقت الامتحان (بيانات افتراضية).',
          'pdf': 'exam_unit_${i + 1}.pdf',
          'deadline': '2025-12-${(20 + i).toString().padLeft(2, '0')}',
        },
      );
    }

    if (q.isNotEmpty) {
      items = items
          .where((m) =>
              m['title']!.contains(q) ||
              m['content']!.contains(q) ||
              (m['deadline'] ?? '').toString().contains(q))
          .toList();
    }

    // Render lists per section
    if (_currentIndex == 0) {
      // Notes
      return Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => NoteCard(
            title: items[index]['title']!,
            content: items[index]['content']!,
            timestamp: items[index]['timestamp'] as String?,
            showTitle: false,
            // Student view: keep actions hidden
          ),
        ),
      );
    } else if (_currentIndex == 1) {
      // Files: same card style as Exams but without deadline and without submit button
      return Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final file = items[index];
            final fileKey = 'file_${file['title']}';
            final isExpanded = _expandedStates[fileKey] ?? false;

            return Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.black12,
                hoverColor: Colors.black12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded
                        ? const Color(0xFF0A84FF)
                        : Colors.black.withOpacity(0.08),
                    width: isExpanded ? 2 : 1,
                  ),
                ),
                child: ExpansionTile(
                  collapsedIconColor: const Color(0xFF0A84FF),
                  iconColor: const Color(0xFF0A84FF),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedStates[fileKey] = expanded;
                    });
                  },
                  title: Text(
                    file['title']!,
                    style: TextStyle(
                      color:
                          isExpanded ? const Color(0xFF0A84FF) : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      file['content']!,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.06), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file,
                              color: Color(0xFF0A84FF)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              file['file']!,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ملف',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Videos: expandable cards with video player
    if (_currentIndex == 2) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final video = items[index];
            return _buildVideoCard(video);
          },
        ),
      );
    }

    // Exams: expandable cards showing teacher PDF and a submit button
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final exam = items[index];
          final examKey = 'exam_${exam['title']}';
          final isExpanded = _expandedStates[examKey] ?? false;

          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.black12,
              hoverColor: Colors.black12,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isExpanded
                      ? const Color(0xFF0A84FF)
                      : Colors.black.withOpacity(0.08),
                  width: isExpanded ? 2 : 1,
                ),
              ),
              child: ExpansionTile(
                collapsedIconColor: const Color(0xFF0A84FF),
                iconColor: const Color(0xFF0A84FF),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedStates[examKey] = expanded;
                  });
                },
                title: Text(
                  exam['title']!,
                  style: TextStyle(
                    color: isExpanded ? const Color(0xFF0A84FF) : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['content']!,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 16, color: Color(0xFF0A84FF)),
                          const SizedBox(width: 6),
                          Text(
                            'آخر موعد: ${exam['deadline']}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                children: [
                  // Teacher uploaded PDF (display only)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.06), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Color(0xFFE74C3C)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            exam['pdf']!,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PDF',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Submit exam button (student action)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 42,
                      child: TextButton.icon(
                        onPressed: () {
                          // TODO: Implement file picker & upload logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('سيتم دعم تسليم الاختبار قريباً')),
                          );
                        },
                        icon: const Icon(Icons.add, color: Color(0xFF0A84FF)),
                        label: const Text(
                          'تسليم الاختبار',
                          style: TextStyle(
                            color: Color(0xFF0A84FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0A84FF),
                          side: const BorderSide(
                              color: Color(0xFF0A84FF), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitles = ['الملاحظات', 'الملفات', 'الفيديوهات', 'الامتحانات'];

    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0A84FF)),
            onPressed: () => context.pop(),
          ),
          title: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              widget.className,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _showSearch ? Icons.close : Icons.search,
                color: const Color(0xFF0A84FF),
              ),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar (toggleable)
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث في ${sectionTitles[_currentIndex]}...',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF0A84FF)),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: Color(0xFF0A84FF), width: 1.2),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: Color(0xFF0A84FF), width: 1.5),
                      ),
                      fillColor: const Color(0xFFF2F2F7),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),
            if (_showSearch) const SizedBox(height: 8),
            // Notes filter chips (only on notes tab)
            if (_currentIndex == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(0, 'الكل'),
                      _buildFilterChip(1, 'آخر يوم'),
                      _buildFilterChip(2, 'آخر أسبوع'),
                      _buildFilterChip(3, 'آخر شهر'),
                    ],
                  ),
                ),
              ),
            if (_currentIndex == 0) const SizedBox(height: 8),
            // Content
            Expanded(child: _buildCurrentSectionList()),
          ],
        ),
        bottomNavigationBar: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                    color: Colors.black.withOpacity(0.08), width: 0.5),
              ),
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: const Color(0xFF0A84FF),
                unselectedItemColor: const Color(0xFF6B7280),
                currentIndex: _currentIndex,
                onTap: (i) {
                  setState(() => _currentIndex = i);
                  if (i == 2) {
                    // Videos tab
                    _loadVideos();
                  }
                },
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sticky_note_2_outlined),
                    activeIcon: Icon(Icons.sticky_note_2),
                    label: 'الملاحظات',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder_outlined),
                    activeIcon: Icon(Icons.folder),
                    label: 'الملفات',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_collection_outlined),
                    activeIcon: Icon(Icons.video_collection),
                    label: 'الفيديوهات',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_outlined),
                    activeIcon: Icon(Icons.assignment),
                    label: 'الامتحانات',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildFilterChip(int value, String label) {
    final bool selected = _notesFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : const Color(0xFF0A84FF),
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _notesFilter = value),
      selectedColor: const Color(0xFF0A84FF),
      backgroundColor: Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: const Color(0xFF0A84FF).withOpacity(0.9),
          width: 1.3,
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final videoKey = 'video_${video['id']}';
    final isExpanded = _expandedStates[videoKey] ?? false;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.black12,
        hoverColor: Colors.black12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isExpanded
              ? Border.all(
                  color: const Color(0xFF0A84FF),
                  width: 2,
                )
              : Border.all(color: Colors.black.withOpacity(0.08), width: 1),
        ),
        child: ExpansionTile(
          collapsedIconColor: const Color(0xFF0A84FF),
          iconColor: const Color(0xFF0A84FF),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStates[videoKey] = expanded;
            });
          },
          title: Text(
            video['title']!,
            style: TextStyle(
              color: isExpanded ? const Color(0xFF0A84FF) : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              video['content']!,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          children: [
            // Video player container
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.black.withOpacity(0.08), width: 1),
              ),
              child: Stack(
                children: [
                  // Video thumbnail/placeholder
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.video_collection,
                        color: Colors.black38,
                        size: 48,
                      ),
                    ),
                  ),
                  // Play button overlay
                  Center(
                    child: GestureDetector(
                      onTap: () => _playVideo(video['url']!),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  // Fullscreen button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _playVideoFullscreen(video['url']!),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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

  void _playVideo(String videoUrl) {
    // TODO: Implement video player
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تشغيل الفيديو: $videoUrl')),
    );
  }

  void _playVideoFullscreen(String videoUrl) {
    // TODO: Implement fullscreen video player
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تشغيل الفيديو في وضع ملء الشاشة: $videoUrl')),
    );
  }
}
