import 'package:it_planner/dto/auth/verify_request.dart';
import 'package:it_planner/dto/auth/verify_response.dart';
import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../theme/colors.dart';

class VerificationScreen extends StatefulWidget {
  final String username;

  const VerificationScreen({Key? key, required this.username}) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final _authService = AuthService();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Настраиваем фокус для перехода между полями
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && i < _focusNodes.length - 1) {
          _focusNodes[i + 1].requestFocus();
        }
      });
    }
  }

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
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
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
                    // Иконка проверки
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Заголовок
                    const Text(
                      'Подтвердите свой Email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Описание
                    Text(
                      'Мы послали код верификации на \n${widget.username}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Поля для ввода кода
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey,
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                offset: Offset(0, 5),
                                blurRadius: 10,
                                spreadRadius: -3,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              if (value.length == 1 && index < 3) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                              
                              // Автоматическая отправка при заполнении всех полей
                              if (_isCodeComplete() && index == 3) {
                                _verifyCode();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Сообщение об ошибке
                    if (_errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    if (_errorMessage.isNotEmpty) const SizedBox(height: 20),
                    
                    // Кнопка подтверждения
                    Container(
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
                          onTap: _isLoading ? null : _verifyCode,
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
                                    'Подтвердить',
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
                    
                    const SizedBox(height: 15),
                    
                    // Кнопка возврата
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/register');
                          },
                          child: Ink(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Вернуться к регистрации',
                                  style: TextStyle(
                                    color: AppColors.primary,
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
                    
                    // Ссылка для повторной отправки кода
                    GestureDetector(
                      onTap: _resendCode,
                      child: const Text(
                        "Не получили код? Отправить еще раз",
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

  bool _isCodeComplete() {
    return _codeControllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getVerificationCode() {
    return _codeControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
  final code = _getVerificationCode();
  
  if (code.length != 4) {
    setState(() {
      _errorMessage = 'Пожалуйста введите 4-х значный код';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final request = VerifyRequest(
      username: widget.username,
      code: code,
    );

    final VerifyResponse response = await _authService.verifyEmail(request);
    
    // Используем новые методы для проверки статуса
    if (response.isSuccess) {
      // Успешная верификация
      _handleSuccess(response);
    } else if (response.isError) {
      // Ошибка от бэкенда
      setState(() {
        _errorMessage = response.message;
      });
    } else {
      // Неизвестный статус
      setState(() {
        _errorMessage = 'Ошибка верификации: ${response.message}';
      });
    }
    
  } catch (e) {
    setState(() {
      _errorMessage = e.toString().replaceAll('Ошибка: ', '');
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  void _handleSuccess(VerifyResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message),
        backgroundColor: Colors.green,
      ),
    );
    
    // Переход на страницу логина после успешной верификации
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void _resendCode() {
    // Здесь можно добавить запрос на повторную отправку кода
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Код верификации был отправлен еще раз на ваш email'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}