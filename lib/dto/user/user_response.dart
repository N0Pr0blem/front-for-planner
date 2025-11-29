import 'package:flutter/material.dart';
import 'dart:convert';

class UserResponse {
  final String username;
  final String? firstName;
  final String? secondName;
  final String? lastName;
  final String? profileImage; // ← это Base64 строка!
  final DateTime? registrationDate;

  UserResponse({
    required this.username,
    this.firstName,
    this.secondName,
    this.lastName,
    this.profileImage,
    this.registrationDate,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      secondName: json['secondName'] as String?,
      lastName: json['lastName'] as String?,
      profileImage: json['profileImage'] as String?,
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : null,
    );
  }

  // Помощник: получить полное имя
  String get fullName {
    final parts = [
      firstName,
      secondName,
      lastName,
    ]..removeWhere((s) => s == null || s.isEmpty);
    return parts.join(' ').trim();
  }

  // Помощник: получить имя для отображения (или username)
  String get displayName {
    return fullName.isNotEmpty ? fullName : username;
  }

  // Помощник: проверить, есть ли аватарка
  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;

  // Помощник: создать ImageWidget из Base64
  Widget get avatarWidget {
    if (!hasProfileImage) {
      return Icon(Icons.person, color: Colors.white, size: 24);
    }

    try {
      final bytes = base64Decode(profileImage!);
      return Image.memory(bytes, width: 24, height: 24, fit: BoxFit.cover);
    } catch (e) {
      return Icon(Icons.person, color: Colors.white, size: 24);
    }
  }
}