// dto/comment/comment_response.dart
class CommentResponse {
  final int id;
  final String text;
  final DateTime creationDate;
  final int taskId;
  final CommentAuthor author;

  CommentResponse({
    required this.id,
    required this.text,
    required this.creationDate,
    required this.taskId,
    required this.author,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      id: json['id'] as int,
      text: json['text'] as String,
      creationDate: DateTime.parse(json['creation_date'] as String),
      taskId: json['task_id'] as int,
      author: CommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'creation_date': creationDate.toIso8601String(),
      'task_id': taskId,
      'author': author.toJson(),
    };
  }
}

class CommentAuthor {
  final String username;
  final String firstName;
  final String secondName;
  final String lastName;
  final String? profileImage; // теперь это base64 строка
  final DateTime registrationDate;

  CommentAuthor({
    required this.username,
    required this.firstName,
    required this.secondName,
    required this.lastName,
    this.profileImage,
    required this.registrationDate,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      secondName: json['secondName'] as String,
      lastName: json['lastName'] as String,
      profileImage: json['profileImage'] as String?,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'firstName': firstName,
      'secondName': secondName,
      'lastName': lastName,
      'profileImage': profileImage,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  String get fullName {
    final parts = <String>[];
    if (firstName.isNotEmpty) parts.add(firstName);
    if (secondName.isNotEmpty) parts.add(secondName);
    if (lastName.isNotEmpty) parts.add(lastName);
    
    if (parts.isEmpty) {
      return username.split('@').first;
    }
    return parts.join(' ');
  }

  String get displayName {
    final name = fullName;
    if (name.isNotEmpty && name != username.split('@').first) {
      return '$name ($username)';
    }
    return username;
  }
}