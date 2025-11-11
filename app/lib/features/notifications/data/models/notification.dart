import 'package:flutter/material.dart';

class Notification {
  final String id; // UUID
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final bool isUnread;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.readAt,
    required this.isUnread,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      isUnread: json['is_unread'] as bool? ?? (json['read_at'] == null),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      if (data != null) 'data': data,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'is_unread': isUnread,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  IconData get icon {
    switch (type) {
      case 'due_item_reminder':
        return Icons.calendar_today;
      case 'service_request_update':
        return Icons.support_agent;
      case 'system_alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'due_item_reminder':
        return Colors.orange;
      case 'service_request_update':
        return Colors.blue;
      case 'system_alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

