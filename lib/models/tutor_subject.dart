class TutorSubject {
  final int id;
  final int userId;
  final int subjectId;
  final String description;
  final String? image;
  final String status;
  final Subject subject;

  TutorSubject({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.description,
    this.image,
    required this.status,
    required this.subject,
  });

  factory TutorSubject.fromJson(Map<String, dynamic> json) {
    print('🔍 DEBUG - Parseando TutorSubject: ID=${json['id']}, Subject ID=${json['subject_id']}, Nombre=${json['subject']?['name'] ?? 'N/A'}');
    return TutorSubject(
      id: json['id'],
      userId: json['user_id'],
      subjectId: json['subject_id'],
      description: json['description'] ?? '',
      image: json['image'],
      status: json['status'] ?? 'active',
      subject: Subject.fromJson(json['subject']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'description': description,
      'image': image,
      'status': status,
      'subject': subject.toJson(),
    };
  }
}

class Subject {
  final int id;
  final String name;
  final int subjectGroupId;

  Subject({
    required this.id,
    required this.name,
    required this.subjectGroupId,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      subjectGroupId: json['subject_group_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject_group_id': subjectGroupId,
    };
  }
}
