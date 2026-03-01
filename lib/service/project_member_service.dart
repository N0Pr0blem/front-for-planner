import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/project/project_member_response.dart';
import '../dto/project/invite_member_request.dart';
import '../utils/token_storage.dart';

class ProjectMemberService {
  static const String _baseUrl = 'http://192.168.0.103:8080/api/v1';

  Future<List<ProjectMemberResponse>> getProjectMembers(int projectId) async {
    try {
      print('🔍 Getting project members for project ID: $projectId');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = Uri.parse('$_baseUrl/project/$projectId/employee');
      print('🌐 Making request to: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        if (responseBody.isEmpty) {
          print('⚠️ Response body is empty');
          return [];
        }

        try {
          final dynamic decoded = json.decode(responseBody);
          
          if (decoded is List) {
            print('✅ Received list of ${decoded.length} members');
            
            final members = <ProjectMemberResponse>[];
            for (var i = 0; i < decoded.length; i++) {
              try {
                final item = decoded[i];
                print('🔍 Parsing member $i: $item');
                
                if (item is Map<String, dynamic>) {
                  final member = ProjectMemberResponse.fromJson(item);
                  members.add(member);
                  print('✅ Successfully parsed member $i: ${member.user.fullName}');
                } else {
                  print('❌ Member $i is not a Map, type: ${item.runtimeType}');
                }
              } catch (e, stackTrace) {
                print('❌ Error parsing member $i: $e');
                print('Stack trace: $stackTrace');
                // Пропускаем проблемного пользователя, но продолжаем загрузку остальных
                continue;
              }
            }
            
            print('🎉 Successfully loaded ${members.length} members');
            return members;
          } else {
            print('❌ Response is not a List, type: ${decoded.runtimeType}');
            throw Exception('Expected List but got ${decoded.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('❌ JSON parsing error: $e');
          print('Stack trace: $stackTrace');
          throw Exception('Failed to parse JSON response: $e');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('💥 Error in getProjectMembers: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Остальные методы остаются без изменений
  Future<void> inviteMember(int projectId, InviteMemberRequest request) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

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
    if (token == null) {
      throw Exception('Token not found');
    }

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
    if (token == null) {
      throw Exception('Token not found');
    }

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