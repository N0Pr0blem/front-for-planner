// widgets/comments_section.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../service/comment_service.dart';
import '../dto/comment/comment_response.dart';
import '../theme/colors.dart';

class CommentsSection extends StatefulWidget {
  final int taskId;

  const CommentsSection({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<CommentResponse> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _editingCommentId;
  bool _showAddForm = false;
  
  // Контроллеры создаем лениво, только когда нужны
  TextEditingController? _commentController;
  TextEditingController? _editController;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void didUpdateWidget(CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.taskId != oldWidget.taskId) {
      // Очищаем старые контроллеры
      _disposeControllers();
      // Перезагружаем данные
      _loadComments();
      setState(() {
        _showAddForm = false;
        _editingCommentId = null;
      });
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _commentController?.dispose();
    _editController?.dispose();
    _commentController = null;
    _editController = null;
  }

  TextEditingController _getCommentController() {
    _commentController ??= TextEditingController();
    return _commentController!;
  }

  TextEditingController _getEditController() {
    _editController ??= TextEditingController();
    return _editController!;
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await CommentService.getTaskComments(widget.taskId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки комментариев: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки комментариев: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createComment() async {
    final controller = _getCommentController();
    if (controller.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newComment = await CommentService.createComment(
        taskId: widget.taskId,
        text: controller.text.trim(),
      );

      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
          controller.clear();
          _isSubmitting = false;
          _showAddForm = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания комментария: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateComment() async {
    final controller = _getEditController();
    if (controller.text.trim().isEmpty || _editingCommentId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedComment = await CommentService.updateComment(
        taskId: widget.taskId,
        commentId: _editingCommentId!,
        text: controller.text.trim(),
      );

      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == _editingCommentId);
          if (index != -1) {
            _comments[index] = updatedComment;
          }
          _editingCommentId = null;
          controller.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления комментария: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить комментарий'),
        content: const Text('Вы уверены, что хотите удалить этот комментарий?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: TextStyle(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await CommentService.deleteComment(
        taskId: widget.taskId,
        commentId: commentId,
      );

      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == commentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Комментарий удален'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления комментария: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startEditing(CommentResponse comment) {
    final controller = _getEditController();
    setState(() {
      _editingCommentId = comment.id;
      controller.text = comment.text;
    });
  }

  void _cancelEditing() {
    final controller = _getEditController();
    setState(() {
      _editingCommentId = null;
      controller.clear();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${date.day}.${date.month}.${date.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин назад';
    } else {
      return 'только что';
    }
  }

  Widget _buildAvatar(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) {
      return _buildDefaultAvatar();
    }
    
    try {
      // Проверяем, является ли строка base64
      if (profileImage.contains('.jpg') || profileImage.contains('.png')) {
        return _buildDefaultAvatar();
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          base64Decode(profileImage),
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } catch (e) {
      print('Ошибка декодирования base64: $e');
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.person,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок с кнопкой +
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Комментарии',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: AppColors.primary, size: 20),
                onPressed: () {
                  setState(() {
                    _showAddForm = !_showAddForm;
                    if (!_showAddForm) {
                      _getCommentController().clear();
                    }
                  });
                },
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Форма добавления комментария
        if (_showAddForm)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _getCommentController(),
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Напишите комментарий...',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                Divider(height: 1, color: AppColors.cardBorder),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAddForm = false;
                            _getCommentController().clear();
                          });
                        },
                        child: Text(
                          'Отмена',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _createComment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Отправить'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Список комментариев
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                'Нет комментариев',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            key: PageStorageKey('comments_list_${widget.taskId}'),
            itemCount: _comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final isEditing = _editingCommentId == comment.id;

              return Container(
                key: ValueKey(comment.id),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
                ),
                child: isEditing
                    ? _buildEditMode(comment)
                    : _buildViewMode(comment),
              );
            },
          ),
      ],
    );
  }

  Widget _buildViewMode(CommentResponse comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildAvatar(comment.author.profileImage),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(comment.creationDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.textHint, size: 20),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.cardBorder),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _startEditing(comment);
                } else if (value == 'delete') {
                  _deleteComment(comment.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 12),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          comment.text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(CommentResponse comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _getEditController(),
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelEditing,
              child: Text(
                'Отмена',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _updateComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ],
    );
  }
}