import 'package:cloud_firestore/cloud_firestore.dart';

enum CommissionType {
  request('request', '委託需求'),
  offer('offer', '接單展示');

  final String value;
  final String label;

  const CommissionType(this.value, this.label);

  static CommissionType parse(String? value) =>
      value == 'offer' ? CommissionType.offer : CommissionType.request;
}

class Commission {
  static const hideAfterReports = 3;

  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final CommissionType type;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String budgetText;
  final Timestamp? deadline;
  final String contact;
  final List<String> imageUrls;
  final bool isNsfw;
  final bool isOpen;
  final int reportCount;
  final Timestamp? createdAt;

  const Commission({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.budgetText,
    required this.deadline,
    required this.contact,
    required this.imageUrls,
    required this.isNsfw,
    required this.isOpen,
    required this.reportCount,
    required this.createdAt,
  });

  bool get hiddenByReports => reportCount >= hideAfterReports;

  bool get expired =>
      deadline != null && deadline!.toDate().isBefore(DateTime.now());

  factory Commission.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Commission(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      type: CommissionType.parse(data['type'] as String?),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      tags: List<String>.from(data['tags'] ?? const []),
      budgetText: data['budgetText'] as String? ?? '',
      deadline: data['deadline'] as Timestamp?,
      contact: data['contact'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? const []),
      isNsfw: data['isNsfw'] == true,
      isOpen: (data['status'] as String? ?? 'open') == 'open',
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'type': type.value,
        'title': title,
        'description': description,
        'category': category,
        'tags': tags,
        'budgetText': budgetText,
        if (deadline != null) 'deadline': deadline,
        'contact': contact,
        'imageUrls': imageUrls,
        'isNsfw': isNsfw,
        'status': 'open',
        'reportCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
