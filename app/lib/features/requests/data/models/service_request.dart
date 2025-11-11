import 'package:flutter/material.dart';

class ServiceRequest {
  final int id;
  final String title;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String? category;
  final Map<String, dynamic> createdBy;
  final Map<String, dynamic>? assignedTo;
  final int? commentsCount;
  final List<ServiceRequestComment>? comments;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.category,
    required this.createdBy,
    this.assignedTo,
    this.commentsCount,
    this.comments,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      category: json['category'] as String?,
      createdBy: json['created_by'] as Map<String, dynamic>,
      assignedTo: json['assigned_to'] as Map<String, dynamic>?,
      commentsCount: json['comments_count'] as int?,
      comments: json['comments'] != null
          ? (json['comments'] as List<dynamic>)
              .map((c) => ServiceRequestComment.fromJson(c))
              .toList()
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      if (category != null) 'category': category,
      'created_by': createdBy,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (commentsCount != null) 'comments_count': commentsCount,
      if (comments != null) 'comments': comments!.map((c) => c.toJson()).toList(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Aberto';
      case 'in_progress':
        return 'Em Progresso';
      case 'resolved':
        return 'Resolvido';
      case 'closed':
        return 'Fechado';
      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Baixa';
      case 'medium':
        return 'Média';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class ServiceRequestComment {
  final int id;
  final String comment;
  final bool isInternal;
  final Map<String, dynamic> user;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequestComment({
    required this.id,
    required this.comment,
    required this.isInternal,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequestComment.fromJson(Map<String, dynamic> json) {
    return ServiceRequestComment(
      id: json['id'] as int,
      comment: json['comment'] as String,
      isInternal: json['is_internal'] as bool? ?? false,
      user: json['user'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'is_internal': isInternal,
      'user': user,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

