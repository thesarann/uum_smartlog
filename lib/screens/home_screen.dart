import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/study_session.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const int _pageSize = 10;

  List<StudySession> _sessions = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Run after first frame so Scaffold exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPage(1);
    });
  }

  Future<void> _loadPage(int page) async {
    debugPrint('LOAD PAGE $page');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final total = await _dbHelper.getTotalCount();
      final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();

      int targetPage = page;
      if (targetPage > totalPages) targetPage = totalPages;
      if (targetPage < 1) targetPage = 1;

      final rows = total == 0
          ? <StudySession>[]
          : await _dbHelper.getSessionsPaged(
        page: targetPage,
        pageSize: _pageSize,
      );

      debugPrint('TOTAL=$total PAGES=$totalPages ROWS=${rows.length}');

      if (!mounted) return;
      setState(() {
        _sessions = rows;
        _totalRecords = total;
        _totalPages = totalPages;
        _currentPage = targetPage;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('DB ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load records:\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadPage(_currentPage);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('List refreshed from database.')),
    );
  }

  Future<void> _openAddForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddEditScreen()),
    );
    if (saved == true) {
      await _loadPage(1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openEditForm(StudySession session) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEditScreen(session: session)),
    );
    if (saved == true) {
      await _loadPage(_currentPage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDetailsDialog(StudySession session) {
    String created = session.createdAt;
    try {
      created = DateFormat('dd MMM yyyy, hh:mm a')
          .format(DateTime.parse(session.createdAt));
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(session.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Subject', session.subject),
              _detailRow('Duration', '${session.durationMinutes} minutes'),
              _detailRow('Notes',
                  (session.notes?.isNotEmpty ?? false) ? session.notes! : '—'),
              _detailRow('Created', created),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openEditForm(session);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15)),
        const Divider(height: 16),
      ],
    ),
  );

  Future<void> _confirmDelete(StudySession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text(
            'Are you sure you want to delete "${session.title}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dbHelper.deleteSession(session.id!);
      await _loadPage(_currentPage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Record deleted.'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadPage(_currentPage),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No study sessions yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the + button to log your first study session.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final s = _sessions[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(
              backgroundColor:
              const Color(0xFF1E3A8A).withOpacity(0.1),
              child: const Icon(Icons.timer_outlined, color: Color(0xFF1E3A8A)),
            ),
            title: Text(s.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s.subject} • ${s.durationMinutes} min'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDetailsDialog(s),
            onLongPress: () => _confirmDelete(s),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    final prevEnabled = _currentPage > 1 && _totalRecords > 0;
    final nextEnabled = _currentPage < _totalPages && _totalRecords > 0;

    return Material(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed:
                prevEnabled ? () => _loadPage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Page $_currentPage / $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$_totalRecords record${_totalRecords == 1 ? '' : 's'}',
                    style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed:
                nextEnabled ? () => _loadPage(_currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UUM SmartLog'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh from database',
            onPressed: _isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      bottomNavigationBar: _buildPagination(),
    );
  }
}