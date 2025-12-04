import 'package:IT_Planner/dto/auth/auth_request.dart';
import 'package:IT_Planner/dto/auth/auth_response.dart';
import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../screen/task_page.dart';
import '../../theme/colors.dart';
import '../../service/main_service.dart';
import '../../data/user_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    var container = Container(
  alignment: Alignment.center,
  padding: const EdgeInsets.only(top: 10),
  child: GestureDetector(
    onTap: () {
      Navigator.pushReplacementNamed(context, '/register');
    },
    child: const Text(
      "Don't have an account? Sign Up",
      style: TextStyle(
        fontSize: 12,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Левая часть с картинкой (только на широких экранах)
          if (isWideScreen) Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/background_main.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.4), // Затемнение
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Добро пожаловать',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Войдите в свою учетную запись, чтобы продолжить',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Правая часть с формой
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 25),
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    minWidth: 350,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppGradients.cardBackground,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.cardBorder, width: 5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowPrimary,
                        offset: Offset(0, 30),
                        blurRadius: 30,
                        spreadRadius: -20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Форма
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Поле email/username
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    offset: Offset(0, 10),
                                    blurRadius: 10,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: 'E-mail',
                                  hintStyle: const TextStyle(color: AppColors.textHint),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Поле пароля
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    offset: Offset(0, 10),
                                    blurRadius: 10,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(color: AppColors.textHint),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            // Забыли пароль
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 10, top: 10),
                              child: GestureDetector(
                                onTap: () {
                                  // Навигация на экран восстановления пароля
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Кнопка входа
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowPrimary.withOpacity(_isLoading ? 0.5 : 0.878),
                                    offset: const Offset(0, 20),
                                    blurRadius: 10,
                                    spreadRadius: -15,
                                  ),
                                ],
                              ),
                              child: Material(
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _isLoading ? null : _login,
                                  child: Ink(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.primaryButton,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.textOnPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Сообщение об ошибке
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: AppColors.textError,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      container,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final request = AuthRequest(
          username: _usernameController.text,
          password: _passwordController.text,
        );

        final AuthResponse response = await _authService.login(request);
        _handleSuccess(response);
        
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSuccess(AuthResponse response) async {
  if (response.token != null) {
    await _saveToken(response.token!);
    
    try {
      final mainService = MainService();
      final user = await mainService.getProfile();
      UserCache.setUser(user);
      
    } catch (e) {
      print('Не удалось загрузить профиль сразу после логина: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully signed in!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TasksPage()),
    );
  } else {
    setState(() {
      _errorMessage = 'No token received';
    });
  }
}

  Future<void> _saveToken(String token) async {
    print('Token received: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}