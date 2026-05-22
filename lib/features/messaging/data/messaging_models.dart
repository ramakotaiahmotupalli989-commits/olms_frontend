/// EduCinema LMS — Messaging Models
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum ConversationCategory {
  doubt('Doubt', Icons.help_outline_rounded, AppColors.info),
  academic('Academic', Icons.menu_book_rounded, AppColors.featurePurple),
  attendance('Attendance', Icons.how_to_reg_rounded, AppColors.warning),
  fee('Fee', Icons.receipt_long_rounded, AppColors.success),
  general('General', Icons.forum_outlined, AppColors.textSecondary);

  final String label;
  final IconData icon;
  final Color color;

  const ConversationCategory(this.label, this.icon, this.color);

  static ConversationCategory fromString(String category) {
    return ConversationCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == category.toLowerCase(),
      orElse: () => ConversationCategory.general,
    );
  }
}

enum ConversationStatus {
  open('Open', AppColors.info),
  resolved('Resolved', AppColors.success),
  closed('Closed', AppColors.textSecondary);

  final String label;
  final Color color;

  const ConversationStatus(this.label, this.color);

  static ConversationStatus fromString(String status) {
    return ConversationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => ConversationStatus.open,
    );
  }
}

class UserBrief {
  final int id;
  final String name;
  final String role;
  final String? avatarUrl;

  UserBrief({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  factory UserBrief.fromJson(Map<String, dynamic> json) {
    return UserBrief(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'avatar_url': avatarUrl,
      };
}

class Conversation {
  final int id;
  final int? schoolId;
  final String category;
  final String title;
  final String status;
  final UserBrief initiator;
  final UserBrief teacher;
  final String? subjectName;
  final String? lastMessagePreview;
  final int unreadCount;
  final int messageCount;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    this.schoolId,
    required this.category,
    required this.title,
    required this.status,
    required this.initiator,
    required this.teacher,
    this.subjectName,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.messageCount = 0,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      schoolId: json['school_id'] as int?,
      category: json['category'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      initiator: UserBrief.fromJson(json['initiator'] as Map<String, dynamic>),
      teacher: UserBrief.fromJson(json['teacher'] as Map<String, dynamic>),
      subjectName: json['subject_name'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      messageCount: json['message_count'] as int? ?? 0,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  ConversationCategory get categoryEnum => ConversationCategory.fromString(category);
  ConversationStatus get statusEnum => ConversationStatus.fromString(status);
}

class Message {
  final int id;
  final int conversationId;
  final UserBrief sender;
  final String content;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      sender: UserBrief.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
