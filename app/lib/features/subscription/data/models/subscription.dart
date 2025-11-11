import 'package:flutter/material.dart';

class Subscription {
  final int id;
  final String plan; // 'free', 'basic', 'premium', 'enterprise'
  final String status; // 'active', 'canceled', 'past_due', 'trialing'
  final bool isActive;
  final bool isOnTrial;
  final bool isCanceled;
  final DateTime? trialEndsAt;
  final DateTime? endsAt;
  final Map<String, dynamic> planLimits;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.isActive,
    required this.isOnTrial,
    required this.isCanceled,
    this.trialEndsAt,
    this.endsAt,
    required this.planLimits,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      plan: json['plan'] as String,
      status: json['status'] as String,
      isActive: json['is_active'] as bool? ?? false,
      isOnTrial: json['is_on_trial'] as bool? ?? false,
      isCanceled: json['is_canceled'] as bool? ?? false,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      planLimits: json['plan_limits'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan': plan,
      'status': status,
      'is_active': isActive,
      'is_on_trial': isOnTrial,
      'is_canceled': isCanceled,
      if (trialEndsAt != null) 'trial_ends_at': trialEndsAt!.toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt!.toIso8601String(),
      'plan_limits': planLimits,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get planName {
    switch (plan) {
      case 'free':
        return 'Gratuito';
      case 'basic':
        return 'Básico';
      case 'premium':
        return 'Premium';
      case 'enterprise':
        return 'Empresarial';
      default:
        return plan;
    }
  }

  Color get planColor {
    switch (plan) {
      case 'free':
        return Colors.grey;
      case 'basic':
        return Colors.blue;
      case 'premium':
        return Colors.purple;
      case 'enterprise':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

