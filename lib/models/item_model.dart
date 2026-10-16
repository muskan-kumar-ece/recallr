import 'package:cloud_firestore/cloud_firestore.dart';

class RecallItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isCompleted;

  RecallItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isCompleted = false,
  });

  factory RecallItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RecallItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isCompleted': isCompleted,
    };
  }
}