import '../dto/user/user_response.dart';

class UserCache {
  static UserResponse? _user;

  static void setUser(UserResponse user) {
    _user = user;
  }

  static UserResponse? getUser() => _user;

  static void clear() {
    _user = null;
  }
}