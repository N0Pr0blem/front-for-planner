// widgets/ai_chat_dialog.dart
import 'package:flutter/material.dart';
import '../service/ai_service.dart';
import '../dto/ai/ai_request_response.dart';
import '../theme/colors.dart';

class AIChatDialog extends StatefulWidget {
  const AIChatDialog({Key? key}) : super(key: key);

  @override
  State<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;
  String? _response;
  AIRequestResponse? _lastAIResponse;
  bool _isSaving = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      _showSnackBar('Введите вопрос', AppColors.textError);
      return;
    }

    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final aiResponse = await AIService.sendAIRequest(
        request: _questionController.text,
        pattern: 'CUSTOM',
      );
      
      setState(() {
        _isLoading = false;
        _response = aiResponse.response;
        _lastAIResponse = aiResponse;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Ошибка: $e', AppColors.textError);
    }
  }

  Future<void> _saveResponse() async {
    if (_lastAIResponse == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await AIService.saveAIResponse(_lastAIResponse!);
      _showSnackBar('Ответ сохранен', AppColors.primary);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Ошибка сохранения: $e', AppColors.textError);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600, // Увеличили ширину
        constraints: const BoxConstraints(maxHeight: 800), // Увеличили высоту
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.textOnPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Спросить ИИ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textOnPrimary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Содержимое
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Увеличенное поле ввода
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: 'Введите вопрос',
                          hintText: 'Напишите ваш вопрос здесь...',
                          labelStyle: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 16,
                          ),
                          hintStyle: TextStyle(
                            color: AppColors.textHint.withOpacity(0.5),
                            fontSize: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.question_answer,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                        ),
                        maxLines: 5,
                        minLines: 3,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Кнопка отправки
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendQuestion,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 20),
                        label: Text(
                          _isLoading ? 'Отправка...' : 'Отправить',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    
                    // Ответ
                    if (_response != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Ответ ИИ:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _response!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_lastAIResponse != null) ...[
                              const SizedBox(height: 16),
                              Divider(color: AppColors.shadowLight),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Время обработки: ${_lastAIResponse!.processingTimeMs} мс',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Кнопки действий
            if (_response != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.shadowLight),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Закрыть'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.textHint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveResponse,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Сохранение...' : 'Сохранить ответ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}