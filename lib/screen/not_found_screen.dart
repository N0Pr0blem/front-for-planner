import 'package:flutter/material.dart';
import '../theme/colors.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3), // Легкое затемнение для контраста
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
                constraints: const BoxConstraints(
                  maxWidth: 500,
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
                    // Иконка ошибки
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Заголовок
                    const Text(
                      '404',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Подзаголовок
                    const Text(
                      'Page Not Found',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Описание
                    const Text(
                      'Извините, но страница которую вы ищете не существует или была перемещена.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Кнопка возврата на логин
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowPrimary,
                            offset: Offset(0, 20),
                            blurRadius: 10,
                            spreadRadius: -15,
                          ),
                        ],
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            // Переход на страницу логина
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Ink(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryButton,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.login,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Перейти к авторизации',
                                  style: TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Дополнительные опции
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Действие "Связаться с поддержкой"
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Функция "Связаться с поддержкой"'),
                              ),
                            );
                          },
                          child: const Text(
                            'Связаться с поддержкой',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              decoration: TextDecoration.underline,
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
    );
  }
}