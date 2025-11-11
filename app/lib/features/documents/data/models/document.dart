import 'package:flutter/material.dart';

class Document {
  final int id;
  final String name;
  final String originalName;
  final String mimeType;
  final int size;
  final String sizeHuman;
  final String? category;
  final String? description;
  final String url;
  final String? documentableType;
  final int? documentableId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.name,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.sizeHuman,
    this.category,
    this.description,
    required this.url,
    this.documentableType,
    this.documentableId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as int,
      name: json['name'] as String,
      originalName: json['original_name'] as String,
      mimeType: json['mime_type'] as String,
      size: json['size'] as int,
      sizeHuman: json['size_human'] as String? ?? _formatBytes(json['size'] as int),
      category: json['category'] as String?,
      description: json['description'] as String?,
      url: json['url'] as String,
      documentableType: json['documentable_type'] as String?,
      documentableId: json['documentable_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_name': originalName,
      'mime_type': mimeType,
      'size': size,
      'size_human': sizeHuman,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      'url': url,
      if (documentableType != null) 'documentable_type': documentableType,
      if (documentableId != null) 'documentable_id': documentableId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  IconData get icon {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('application/pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color get color {
    if (mimeType.startsWith('image/')) {
      return Colors.blue;
    } else if (mimeType.startsWith('application/pdf')) {
      return Colors.red;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Colors.blue;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }
}

