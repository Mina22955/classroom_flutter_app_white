import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/note_card.dart';
import '../widgets/gradient_bg.dart';
import '../widgets/secure_pdf_viewer.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

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
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _files = [];
  bool _isLoadingVideos = false;
  bool _isLoadingNotes = false;
  bool _isLoadingFiles = false;
  bool _notesLoaded = false; // Track if notes have been loaded
  bool _filesLoaded = false; // Track if files have been loaded
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
    _loadNotes(); // Load notes when entering the class
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

  Future<void> _loadNotes() async {
    print('Loading notes for classId: ${widget.classId}');
    setState(() => _isLoadingNotes = true);
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      print('Token available: ${token != null}');
      print('Token preview: ${token?.substring(0, 10)}...');

      final notes = await _apiService.getClassNotes(
        classId: widget.classId,
        accessToken: token,
      );
      print('Notes loaded: ${notes.length} notes');
      print('Notes data: $notes');
      setState(() {
        _notes = notes;
        _notesLoaded = true;
      });
    } catch (e) {
      print('Error loading notes: $e');
    } finally {
      setState(() => _isLoadingNotes = false);
    }
  }

  Future<void> _loadFiles() async {
    print('Loading files for classId: ${widget.classId}');
    setState(() => _isLoadingFiles = true);
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      print('Token available: ${token != null}');
      print('Token preview: ${token?.substring(0, 10)}...');

      final files = await _apiService.getClassFiles(
        classId: widget.classId,
        accessToken: token,
      );
      print('Files loaded: ${files.length} files');
      print('Files data: $files');
      setState(() {
        _files = files;
        _filesLoaded = true;
      });
    } catch (e) {
      print('Error loading files: $e');
    } finally {
      setState(() => _isLoadingFiles = false);
    }
  }

  // Build filtered items for current section based on the search query
  Widget _buildCurrentSectionList() {
    final String q = _searchController.text.trim();

    List<Map<String, dynamic>> items;
    if (_currentIndex == 0) {
      // الملاحظات (حائط ملاحظات - قراءة فقط)
      if (_isLoadingNotes) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }

      // Convert API notes to the expected format
      print('Processing ${_notes.length} notes from API');
      items = _notes.map((note) {
        print('Processing note: $note');
        // Parse createdAt to format timestamp
        String timestamp = 'غير محدد';
        if (note['createdAt'] != null) {
          try {
            final date = DateTime.parse(note['createdAt']);
            timestamp =
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (e) {
            print('Error parsing date: $e');
          }
        }

        final processedNote = {
          'title': 'ملاحظة',
          'content': note['msg'] ?? 'لا يوجد محتوى',
          'timestamp': timestamp,
        };
        print('Processed note: $processedNote');
        return processedNote;
      }).toList();
      print('Final items count: ${items.length}');

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
      // الملفات: استخدام البيانات من API
      if (_isLoadingFiles) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }
      items = _files
          .map((file) => {
                'id': file['id'],
                'title': file['name'] ?? 'ملف غير محدد',
                'content': file['description'] ?? 'لا يوجد وصف',
                'pdfUrl': file['pdfUrl'],
                'expiresAt': file['expiresAt'],
              })
          .toList();
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
      if (items.isEmpty) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد ملاحظات بعد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم عرض الملاحظات هنا عندما ينشرها المعلم',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadNotes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
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
          ),
        );
      }

      return Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _loadNotes,
          color: const Color(0xFF0A84FF),
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
        ),
      );
    } else if (_currentIndex == 1) {
      // Files: API data with PDF viewing
      if (items.isEmpty) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد ملفات بعد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم عرض الملفات هنا عندما يرفعها المعلم',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadFiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Debug button to test API
                ElevatedButton.icon(
                  onPressed: () async {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final token = authProvider.token;
                    print('=== MANUAL API TEST ===');
                    print('Class ID: ${widget.classId}');
                    print('Class Name: ${widget.className}');
                    print(
                        'Token: ${token != null ? 'Available' : 'Not available'}');
                    if (token != null) {
                      print('Token preview: ${token.substring(0, 10)}...');
                    }
                    await _loadFiles();
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('اختبار API'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _loadFiles,
          color: const Color(0xFF0A84FF),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = items[index];
              final fileKey = 'file_${file['id']}';
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
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                            const Icon(Icons.picture_as_pdf,
                                color: Color(0xFFE74C3C)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${file['title']}.pdf',
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
                                  colors: [
                                    Color(0xFF0A84FF),
                                    Color(0xFF007AFF)
                                  ],
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
                      // Open PDF button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 42,
                          child: TextButton.icon(
                            onPressed: () =>
                                _openPdf(file['pdfUrl']!, file['title']!),
                            icon: const Icon(Icons.visibility,
                                color: Color(0xFF0A84FF)),
                            label: const Text(
                              'فتح الملف',
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
            // Removed notes filter chips per request
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
                  if (i == 0 && !_notesLoaded) {
                    // Notes tab - only load if not already loaded
                    _loadNotes();
                  } else if (i == 1 && !_filesLoaded) {
                    // Files tab - only load if not already loaded
                    _loadFiles();
                  } else if (i == 2) {
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

  void _openPdf(String pdfUrl, String fileName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SecurePdfViewer(
          pdfUrl: pdfUrl,
          fileName: fileName,
        ),
      ),
    );
  }
}
