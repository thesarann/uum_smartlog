class StudySession {
  final int? id;
  final String title;
  final String subject;
  final int durationMinutes;
  final String? notes;
  final String createdAt;

  StudySession({
    this.id,
    required this.title,
    required this.subject,
    required this.durationMinutes,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as int?,
      title: map['title'] as String,
      subject: map['subject'] as String,
      durationMinutes: map['durationMinutes'] as int,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }
}