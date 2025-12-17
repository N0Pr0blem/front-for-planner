import 'package:flutter/material.dart';
import 'package:it_planner/dto/user/user_response.dart';
import 'package:it_planner/theme/colors.dart';
import 'package:it_planner/utils/token_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/main_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  UserResponse? _user;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isCheckingAuth = true;
    });
    
    final token = await TokenStorage.getToken();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = token != null && token.isNotEmpty;
        _isCheckingAuth = false;
      });
      
      if (_isAuthenticated) {
        _loadUserProfile();
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final mainService = MainService();
      final user = await mainService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      // Если ошибка при загрузке профиля, считаем пользователя неавторизованным
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _user = null;
        });
      }
    }
  }

  Future<void> _openTasksPage() async {
    final uri = Uri.parse('http://localhost:3000/#/tasks');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть страницу задач')),
      );
    }
  }

  Widget _buildHeaderContent() {
    // Показываем индикатор загрузки во время проверки
    if (_isCheckingAuth) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    // Если авторизован - показываем кнопку задач и аватар
    if (_isAuthenticated) {
      return Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _openTasksPage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: AppGradients.primaryButton,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Задачи',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: _user?.hasProfileImage == true
                    ? ClipOval(child: _user!.avatarWidget)
                    : Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      );
    }

    // Если не авторизован - показываем кнопки входа и регистрации
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text(
              'Войти',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
            child: const Text(
              'Зарегистрироваться',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Хедер
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Fern.com',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                // Отдельный метод для отображения контента хедера
                _buildHeaderContent(),
              ],
            ),
          ),
          // Основной контент
          Expanded(
            child: Stack(
              children: [
                // Фон
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.background,
                          Colors.green[800]!,
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Полупрозрачный слой
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                // Две колонки
                Positioned.fill(
                  child: Row(
                    children: [
                      // Левая половина — текст и кнопки
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWideScreen ? 600 : double.infinity,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: isWideScreen ? 0 : 40,
                              ),
                              child: FadeTransition(
                                opacity: _opacityAnimation,
                                child: Column(
                                  mainAxisAlignment: isWideScreen 
                                      ? MainAxisAlignment.center 
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: isWideScreen ? 0 : 40),
                                    Text(
                                      'Управляйте задачами\nвезде и всегда',
                                      style: TextStyle(
                                        fontSize: isWideScreen ? 44 : 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 6,
                                            color: Colors.black.withOpacity(0.6),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Fern.com доступен как через браузер, так и через мобильное приложение. '
                                        'Создавайте, редактируйте и делитесь задачами — в любое время и с любого устройства.',
                                        style: TextStyle(
                                          fontSize: isWideScreen ? 17 : 15,
                                          color: Colors.white,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: [
                                        // Градиентная кнопка "Начать сейчас"
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Material(
                                            borderRadius: BorderRadius.circular(20),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                                              child: Ink(
                                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                                                decoration: BoxDecoration(
                                                  gradient: AppGradients.primaryButton,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Начать сейчас',
                                                  style: TextStyle(
                                                    color: AppColors.textOnPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Белая кнопка "Войти"
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Material(
                                            borderRadius: BorderRadius.circular(20),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                                              child: Ink(
                                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: AppColors.primary, width: 2),
                                                ),
                                                child: Text(
                                                  'Войти',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Правая половина — телефон по центру
                      if (isWideScreen)
                        Expanded(
                          child: Center(
                            child: FadeTransition(
                              opacity: _opacityAnimation,
                              child: Image.asset(
                                'assets/images/phone.png',
                                height: 640,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // QR-код — справа внизу
                if (isWideScreen)
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/qr.png',
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}