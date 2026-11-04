import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/study_session.dart';

class AddEditScreen extends StatefulWidget {
  final StudySession? session;
  const AddEditScreen({super.key, this.session});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _notesCtrl;
  String? _subject;
  bool _isSaving = false;

  static const List<String> _subjects = [
    'Programming',
    'Mathematics',
    'Database',
    'Networking',
    'English',
    'Business',
    'Other',
  ];

  bool get _isEditMode => widget.session != null;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _durationCtrl = TextEditingController(
      text: s != null ? s.durationMinutes.toString() : '',
    );
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _subject = s?.subject;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSave() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors before saving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isEditMode ? 'Confirm update?' : 'Confirm save?'),
        content: Text(
          _isEditMode
              ? 'Save the changes to this study session?'
              : 'Save this study session to the database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final session = StudySession(
        id: widget.session?.id,
        title: _titleCtrl.text.trim(),
        subject: _subject!,
        durationMinutes: int.parse(_durationCtrl.text.trim()),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: widget.session?.createdAt ??
            DateTime.now().toIso8601String(),
      );

      if (_isEditMode) {
        await _dbHelper.updateSession(session);
      } else {
        await _dbHelper.insertSession(session);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Study Session' : 'Add Study Session'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Session Title *',
                hintText: 'e.g. Flutter basics revision',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Session title is required.';
                }
                if (v.trim().length < 3) {
                  return 'Title must be at least 3 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(
                labelText: 'Subject / Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _subject = v),
              validator: (v) => v == null ? 'Please select a subject.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes) *',
                hintText: 'e.g. 45',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Duration is required.';
                }
                final n = int.tryParse(v.trim());
                if (n == null) return 'Duration must be a whole number.';
                if (n <= 0) return 'Duration must be greater than 0.';
                if (n > 1440) return 'Duration cannot exceed 1440 minutes (24h).';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Topics covered, reflections, etc.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _confirmAndSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(_isEditMode ? 'Update Session' : 'Save Session'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}