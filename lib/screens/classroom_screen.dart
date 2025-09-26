import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoadingVideos = false;
  bool _isLoadingNotes = false;
  bool _isLoadingFiles = false;
  bool _isLoadingTasks = false;
  bool _notesLoaded = false; // Track if notes have been loaded
  bool _filesLoaded = false; // Track if files have been loaded
  bool _tasksLoaded = false; // Track if tasks have been loaded
  // Notes filter: 0=All, 1=Last day, 2=Last week, 3=Last month
  int _notesFilter = 0;

  // Track expansion state for video and exam cards
  final Map<String, bool> _expandedStates = {};
  // Cache for submission status per taskId to avoid repeated calls
  final Map<String, bool> _taskSubmissionStatus = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load data asynchronously without blocking the UI
    Future.microtask(() {
      _loadVideos();
      _loadNotes(); // Load notes when entering the class
    });
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

  Future<void> _loadTasks() async {
    print('Loading tasks for classId: ${widget.classId}');
    setState(() => _isLoadingTasks = true);
    try {
      // Get token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      print('Token available: ${token != null}');
      print('Token preview: ${token?.substring(0, 10)}...');

      final tasks = await _apiService.getClassTasks(
        classId: widget.classId,
        accessToken: token,
      );
      print('Tasks loaded: ${tasks.length} tasks');
      print('Tasks data: $tasks');
      setState(() {
        _tasks = tasks;
        _tasksLoaded = true;
      });
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      setState(() => _isLoadingTasks = false);
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
                'isExpired': file['isExpired'] ?? false,
                'expiresAtFormatted': file['expiresAtFormatted'],
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
      // الامتحانات: استخدام البيانات من API
      if (_isLoadingTasks) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        );
      }
      items = _tasks
          .map((task) => {
                'id': task['id'],
                'title': task['title'] ?? 'امتحان غير محدد',
                'content': task['content'] ?? 'لا يوجد وصف',
                'pdfUrl': task['pdfUrl'],
                'expiresAt': task['expiresAt'],
                'isExpired': task['isExpired'] ?? false,
                'expiresAtFormatted': task['expiresAtFormatted'],
                'deadline': task['deadline'] ?? 'غير محدد',
                'pdf':
                    '${task['title']}.pdf', // For compatibility with existing UI
              })
          .toList();
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file['content']!,
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13),
                          ),
                          if (file['isExpired'] == true) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'انتهت صلاحية الرابط',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (file['expiresAtFormatted'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Color(0xFF0A84FF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ينتهي: ${_formatExpirationDate(file['expiresAtFormatted'])}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
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
                            onPressed: file['isExpired'] == true
                                ? () => _showExpiredDialog(file['title']!)
                                : () =>
                                    _openPdf(file['pdfUrl']!, file['title']!),
                            icon: Icon(
                              file['isExpired'] == true
                                  ? Icons.warning_amber_rounded
                                  : Icons.visibility,
                              color: file['isExpired'] == true
                                  ? Colors.orange
                                  : const Color(0xFF0A84FF),
                            ),
                            label: Text(
                              file['isExpired'] == true
                                  ? 'انتهت الصلاحية'
                                  : 'فتح الملف',
                              style: TextStyle(
                                color: file['isExpired'] == true
                                    ? Colors.orange
                                    : const Color(0xFF0A84FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: file['isExpired'] == true
                                  ? Colors.orange
                                  : const Color(0xFF0A84FF),
                              side: BorderSide(
                                  color: file['isExpired'] == true
                                      ? Colors.orange
                                      : const Color(0xFF0A84FF),
                                  width: 1.5),
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
    if (items.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد امتحانات بعد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم عرض الامتحانات هنا عندما ينشرها المعلم',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTasks,
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
        onRefresh: _loadTasks,
        color: const Color(0xFF0A84FF),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final exam = items[index];
            final examKey = 'exam_${exam['id']}';
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
                  onExpansionChanged: (expanded) async {
                    setState(() {
                      _expandedStates[examKey] = expanded;
                    });
                    if (expanded) {
                      await _checkAndCacheSubmissionStatus(exam['id']!);
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    exam['title']!,
                    style: TextStyle(
                      color:
                          isExpanded ? const Color(0xFF0A84FF) : Colors.black,
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
                        if (exam['isExpired'] == true) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'انتهت صلاحية الامتحان',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else if (exam['expiresAtFormatted'] != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Color(0xFF0A84FF)),
                              const SizedBox(width: 6),
                              Text(
                                'ينتهي: ${_formatExpirationDate(exam['expiresAtFormatted'])}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Color(0xFF0A84FF)),
                              const SizedBox(width: 6),
                              Text(
                                'تاريخ النشر: ${exam['deadline']}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  children: [
                    // Instructions for PDF viewing
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0A84FF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF0A84FF),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'انقر على ملف PDF لعرض الامتحان',
                              style: TextStyle(
                                color: const Color(0xFF0A84FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Teacher uploaded PDF (clickable to open)
                    GestureDetector(
                      onTap: exam['isExpired'] == true
                          ? () => _showExpiredDialog(exam['title']!)
                          : (_taskSubmissionStatus[exam['id']] == true
                              ? () => _showAlreadySubmittedDialog()
                              : () => _openPdf(
                                    exam['pdfUrl']!,
                                    exam['title']!,
                                  )),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: exam['isExpired'] == true
                              ? Colors.orange.withOpacity(0.1)
                              : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: exam['isExpired'] == true
                                  ? Colors.orange.withOpacity(0.3)
                                  : const Color(0xFF0A84FF).withOpacity(0.2),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              exam['isExpired'] == true
                                  ? Icons.warning_amber_rounded
                                  : Icons.picture_as_pdf,
                              color: exam['isExpired'] == true
                                  ? Colors.orange
                                  : const Color(0xFFE74C3C),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                exam['pdf']!,
                                style: TextStyle(
                                    color: exam['isExpired'] == true
                                        ? Colors.orange
                                        : Colors.black,
                                    fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: exam['isExpired'] == true
                                        ? const LinearGradient(
                                            colors: [
                                              Colors.orange,
                                              Colors.deepOrange
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : (_taskSubmissionStatus[exam['id']] ==
                                                true
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF16A34A),
                                                  Color(0xFF22C55E),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFF0A84FF),
                                                  Color(0xFF007AFF)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    exam['isExpired'] == true
                                        ? 'منتهي'
                                        : (_taskSubmissionStatus[exam['id']] ==
                                                true
                                            ? 'تم التسليم'
                                            : 'عرض'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Submit exam button (student action)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 42,
                        child: TextButton.icon(
                          onPressed: exam['isExpired'] == true
                              ? () => _showExpiredExamDialog(exam['title']!)
                              : (_taskSubmissionStatus[exam['id']] == true
                                  ? () => _showAlreadySubmittedDialog()
                                  : () => _submitExamSolution(
                                        exam['id']!,
                                        exam['title']!,
                                      )),
                          icon: Icon(
                            exam['isExpired'] == true
                                ? Icons.warning_amber_rounded
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? Icons.check_circle_outline
                                    : Icons.add),
                            color: exam['isExpired'] == true
                                ? Colors.orange
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF0A84FF)),
                          ),
                          label: Text(
                            exam['isExpired'] == true
                                ? 'انتهت الصلاحية'
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? 'تم التسليم'
                                    : 'تسليم الاختبار'),
                            style: TextStyle(
                              color: exam['isExpired'] == true
                                  ? Colors.orange
                                  : (_taskSubmissionStatus[exam['id']] == true
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF0A84FF)),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: exam['isExpired'] == true
                                ? Colors.orange
                                : (_taskSubmissionStatus[exam['id']] == true
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF0A84FF)),
                            side: BorderSide(
                                color: exam['isExpired'] == true
                                    ? Colors.orange
                                    : (_taskSubmissionStatus[exam['id']] == true
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF0A84FF)),
                                width: 1.5),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitles = ['الملاحظات', 'الملفات', 'الفيديوهات', 'الامتحانات'];

    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
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
        body: SafeArea(
          child: Column(
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
                  } else if (i == 3 && !_tasksLoaded) {
                    // Tasks/Exams tab - only load if not already loaded
                    _loadTasks();
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
    print('=== OPENING PDF ===');
    print('PDF URL: $pdfUrl');
    print('File Name: $fileName');
    print('URL Valid: ${Uri.tryParse(pdfUrl) != null}');

    // Try secure PDF viewer first (in-app viewing)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SecurePdfViewer(
          pdfUrl: pdfUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  String _formatExpirationDate(String? isoDate) {
    if (isoDate == null) return 'غير محدد';

    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} دقيقة';
      } else {
        return 'قريباً';
      }
    } catch (e) {
      return 'غير محدد';
    }
  }

  void _showExpiredDialog(String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'انتهت صلاحية الرابط',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'انتهت صلاحية رابط الملف "$fileName". يرجى تحديث الصفحة أو التواصل مع المعلم للحصول على رابط جديد.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadFiles(); // Refresh files to get new URLs
                },
                child: const Text(
                  'تحديث الملفات',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpiredExamDialog(String examTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'انتهت صلاحية الامتحان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'انتهت صلاحية الامتحان "$examTitle". لم يعد بإمكانك تسليم الحل.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitExamSolution(String taskId, String examTitle) async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;

        if (filePath == null || filePath.isEmpty) {
          _showErrorDialog('خطأ في تحديد الملف',
              'لم يتم تحديد ملف صحيح. يرجى المحاولة مرة أخرى.');
          return;
        }

        // Validate file size before upload (10MB limit)
        final fileSize = file.size;
        if (fileSize > 10 * 1024 * 1024) {
          _showErrorDialog('حجم الملف كبير جداً',
              'حجم الملف يجب أن يكون أقل من 10 ميجابايت.');
          return;
        }

        // Validate file extension
        final fileName = file.name.toLowerCase();
        final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
        final fileExtension = fileName.split('.').last;

        if (!allowedExtensions.contains(fileExtension)) {
          _showErrorDialog('نوع الملف غير مدعوم',
              'الملفات المدعومة: PDF, DOC, DOCX, JPG, JPEG, PNG');
          return;
        }

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF0A84FF)),
                    const SizedBox(height: 16),
                    const Text('جاري تسليم الحل...'),
                    const SizedBox(height: 8),
                    Text(
                      'الملف: ${file.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Get token from AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        if (token == null || token.isEmpty) {
          // Close loading dialog
          Navigator.of(context).pop();
          _showErrorDialog('خطأ في المصادقة', 'يرجى تسجيل الدخول مرة أخرى.');
          return;
        }

        // Get student ID from AuthProvider
        final studentId = authProvider.user?['id']?.toString() ??
            authProvider.user?['_id']?.toString() ??
            '';

        if (studentId.isEmpty) {
          // Close loading dialog
          Navigator.of(context).pop();
          _showErrorDialog('خطأ في المصادقة', 'معرف الطالب غير متوفر.');
          return;
        }

        // Submit the solution
        final submissionResult = await _apiService.submitTaskSolution(
          studentId: studentId,
          classId: widget.classId,
          taskId: taskId,
          filePath: filePath,
          accessToken: token,
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (submissionResult['success'] == true) {
          _showSuccessDialog(
            'تم تسليم الحل بنجاح',
            submissionResult['message'] ?? 'تم تسليم حل الامتحان بنجاح',
          );
          // Mark as submitted locally
          _taskSubmissionStatus[taskId] = true;
          if (mounted) setState(() {});
        } else {
          _showErrorDialog(
            'فشل في تسليم الحل',
            submissionResult['message'] ?? 'حدث خطأ أثناء تسليم الحل',
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      _showErrorDialog('خطا في تسليم الامتحان', errorMessage);
    }
  }

  Future<void> _checkAndCacheSubmissionStatus(String taskId) async {
    try {
      // If already known, skip
      if (_taskSubmissionStatus.containsKey(taskId)) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final studentId = authProvider.user?['id']?.toString() ??
          authProvider.user?['_id']?.toString() ??
          '';

      if (token == null || token.isEmpty || studentId.isEmpty) return;

      final taskDetails = await _apiService.getTaskDetails(
        classId: widget.classId,
        taskId: taskId,
        accessToken: token,
      );

      if (taskDetails == null) return;

      final submittedStudents = (taskDetails['submittedStudents'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final isSubmitted = submittedStudents.contains(studentId);
      _taskSubmissionStatus[taskId] = isSubmitted;
    } catch (e) {
      // Silent fail; keep as not submitted
    }
  }

  void _showAlreadySubmittedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF0A84FF),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'تم التسليم مسبقاً',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'لقد قمت بتسليم هذا الامتحان مسبقاً، ولا يمكنك إعادة التسليم.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'موافق',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'موافق',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'موافق',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
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
