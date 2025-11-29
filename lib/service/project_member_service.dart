import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/project/project_member_response.dart';
import '../dto/project/invite_member_request.dart';
import '../utils/token_storage.dart';

class ProjectMemberService {
  static const String _baseUrl = 'http://localhost:8080/api/v1';

  Future<List<ProjectMemberResponse>> getProjectMembers(int projectId) async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/project/$projectId/employee'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ProjectMemberResponse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load project members: ${response.statusCode}');
    }
  }

  Future<void> inviteMember(int projectId, InviteMemberRequest request) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/project/$projectId/employee'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to invite member: ${response.statusCode}');
    }
  }

  Future<void> updateMemberRole(int projectId, int memberId, UpdateMemberRoleRequest request) async {
    final token = await TokenStorage.getToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/project/$projectId/employee/$memberId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update member role: ${response.statusCode}');
    }
  }

  Future<void> removeMember(int projectId, int memberId) async {
    final token = await TokenStorage.getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/project/$projectId/employee/$memberId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove member: ${response.statusCode}');
    }
  }
}