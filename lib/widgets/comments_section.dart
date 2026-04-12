import 'dart:convert';
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
      _disposeControllers();
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

    setState(() => _isLoading = true);

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
        setState(() => _isLoading = false);
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

    setState(() => _isSubmitting = true);

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
        setState(() => _isSubmitting = false);
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

    setState(() => _isSubmitting = true);

    try {
      final updatedComment = await CommentService.updateComment(
        taskId: widget.taskId,
        commentId: _editingCommentId!,
        text: controller.text.trim(),
      );

      if (mounted) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == _editingCommentId);
          if (index != -1) _comments[index] = updatedComment;
          _editingCommentId = null;
          controller.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
        setState(() => _comments.removeWhere((c) => c.id == commentId));
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
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
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
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: AppColors.primary, size: 22),
                onPressed: () {
                  setState(() {
                    _showAddForm = !_showAddForm;
                    if (!_showAddForm) {
                      _getCommentController().clear();
                    }
                  });
                },
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Форма добавления комментария
        if (_showAddForm)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.background.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                Divider(height: 1, color: AppColors.cardBorder),
                Padding(
                  padding: const EdgeInsets.all(16),
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
                            horizontal: 28,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Отправить',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
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
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background,
                  AppColors.background.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppColors.textHint.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет комментариев',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            key: PageStorageKey('comments_list_${widget.taskId}'),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final isEditing = _editingCommentId == comment.id;
              final isLast = index == _comments.length - 1;

              return Column(
                children: [
                  // ✨ Улучшенная карточка комментария
                  Container(
                    key: ValueKey(comment.id),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isEditing
                        ? _buildEditMode(comment)
                        : _buildViewMode(comment),
                  ),
                  const SizedBox(height: 16),
                ],
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
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(comment.creationDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textHint,
                size: 22,
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.cardBorder),
              ),
              elevation: 8,
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
                      Icon(Icons.edit, size: 18, color: AppColors.primary),
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
        const SizedBox(height: 16),
        Text(
          comment.text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.5,
            letterSpacing: 0.3,
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
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Введите текст комментария...',
            hintStyle: TextStyle(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
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
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _updateComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
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
                  : const Text(
                      'Сохранить',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
