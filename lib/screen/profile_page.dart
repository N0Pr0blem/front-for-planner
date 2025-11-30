import 'package:flutter/material.dart';
import '../dto/user/user_response.dart';
import '../dto/project/project_response.dart';
import '../dto/task/task_response.dart';
import '../service/main_service.dart';
import '../service/project_service.dart';
import '../service/task_service.dart';
import '../utils/token_storage.dart';
import '../theme/colors.dart';
import '../screen/auth/login_screen.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserResponse? _user;
  List<ProjectResponse> _myProjects = [];
  List<TaskResponse> _myTasks = [];
  bool _isLoading = true;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userFuture = MainService().getProfile();
      final projectsFuture = ProjectService().getMyProjects();
      final tasksFuture = TaskService.getMyTasks();

      final results = await Future.wait([
        userFuture,
        projectsFuture,
        tasksFuture,
      ]);

      setState(() {
        _user = results[0] as UserResponse;
        _myProjects = results[1] as List<ProjectResponse>;
        _myTasks = results[2] as List<TaskResponse>;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных профиля: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  void _goBackToTasks() {
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    await TokenStorage.clearToken();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  void _toggleEditProfile() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditingProfile = false;
    });
  }

  Future<void> _createProject(String name) async {
    try {
      await ProjectService().createProject(name);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Проект "$name" создан'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания проекта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProject(int projectId, String projectName) async {
    showDialog(
      context: context,
      builder: (context) => _DeleteProjectDialog(
        projectName: projectName,
        onDelete: () async {
          try {
            await ProjectService().deleteProject(projectId);
            await _loadData();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Проект "$projectName" удален'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка удаления проекта: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateProjectDialog(
        onCreateProject: _createProject,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Левая панель с кнопками (1/4 ширины)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.25,
            child: _NavigationPanel(
              onBack: _goBackToTasks,
              onLogout: _logout,
            ),
          ),

          // Правая панель с контентом (3/4 ширины) - растягиваем на всю высоту
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Секция профиля
            _ProfileSection(
              user: _user!,
              isEditing: _isEditingProfile,
              onEditToggle: _toggleEditProfile,
              onCancelEdit: _cancelEdit,
              onProfileUpdated: _loadData,
            ),

            const SizedBox(height: 32),

            // Секция моих проектов
            _MyProjectsSection(
              projects: _myProjects,
              onCreateProject: _showCreateProjectDialog,
              onDeleteProject: _deleteProject,
            ),

            const SizedBox(height: 32),

            // Секция моих задач
            _MyTasksSection(tasks: _myTasks),
          ],
        ),
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _NavigationPanel({
    Key? key,
    required this.onBack,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.third_background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Кнопка назад к задачам
          _NavButton(
            icon: Icons.arrow_back,
            label: 'Назад к задачам',
            onTap: onBack,
          ),
          
          const SizedBox(height: 32),
          
          _NavButton(
            icon: Icons.person,
            label: 'Профиль',
            isActive: true,
            onTap: () {},
          ),
          
          const Spacer(),
          
          _NavButton(
            icon: Icons.logout,
            label: 'Выйти',
            onTap: onLogout,
            isLogout: true,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isLogout;

  const _NavButton({
    Key? key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    this.isLogout = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout 
                    ? Colors.red 
                    : (isActive ? AppColors.textOnPrimary : AppColors.textHint),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLogout 
                      ? Colors.red 
                      : (isActive ? AppColors.textOnPrimary : AppColors.textHint),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatefulWidget {
  final UserResponse user;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final VoidCallback onCancelEdit;
  final VoidCallback onProfileUpdated;

  const _ProfileSection({
    Key? key,
    required this.user,
    required this.isEditing,
    required this.onEditToggle,
    required this.onCancelEdit,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  __ProfileSectionState createState() => __ProfileSectionState();
}

class __ProfileSectionState extends State<_ProfileSection> {
  late TextEditingController _firstNameController;
  late TextEditingController _secondNameController;
  late TextEditingController _lastNameController;
  PlatformFile? _pickedFile;
  Uint8List? _imageBytes; // Добавляем для хранения байтов изображения

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName ?? '');
    _secondNameController = TextEditingController(text: widget.user.secondName ?? '');
    _lastNameController = TextEditingController(text: widget.user.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _imageBytes = _pickedFile!.bytes; // Сохраняем байты
        });
        print('Файл выбран: ${_pickedFile!.name}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Изображение "${_pickedFile!.name}" выбрано успешно'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Пользователь отменил выбор файла');
      }
    } catch (e) {
      print('Ошибка при выборе файла: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выборе файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
  try {
    if (_pickedFile != null && _imageBytes != null) {
      // Отправляем файл как multipart/form-data
      await MainService().updateProfileWithImage(
        secondName: _secondNameController.text,
        lastName: _lastNameController.text,
        fileBytes: _imageBytes!,
        fileName: _pickedFile!.name,
        mimeType: _pickedFile!.extension ?? 'image/jpeg',
      );
    } else {
      // Отправляем только текстовые данные
      await MainService().updateProfile(
        secondName: _secondNameController.text,
        lastName: _lastNameController.text,
      );
    }
    
    widget.onProfileUpdated();
    widget.onEditToggle();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Профиль обновлен'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка обновления профиля: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Widget _buildAvatar() {
    if (_imageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _imageBytes!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _defaultAvatar(100);
          },
        ),
      );
    }
    
    return widget.user.hasProfileImage
        ? ClipOval(
            child: Image.memory(
              base64Decode(widget.user.profileImage!),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _defaultAvatar(100);
              },
            ),
          )
        : _defaultAvatar(100);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Профиль',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!widget.isEditing)
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Редактировать',
                  onTap: widget.onEditToggle,
                )
              else
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.cancel,
                      label: 'Отмена',
                      onTap: widget.onCancelEdit,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    _ActionButton(
                      icon: Icons.save,
                      label: 'Сохранить',
                      onTap: _saveProfile,
                      color: Colors.green,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (!widget.isEditing) _buildProfileView() else _buildProfileEdit(),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.username,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.user.registrationDate != null)
                Text(
                  'Зарегистрирован: ${_formatDate(widget.user.registrationDate!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileEdit() {
    return Column(
      children: [
        // Аватар с возможностью изменения
        GestureDetector(
          onTap: _pickImage,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Stack(
              children: [
                _buildAvatar(),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Изменить',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Нажмите на фото для выбора изображения с компьютера',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        _EditTextField(
          controller: _firstNameController,
          label: 'Имя',
          hintText: 'Введите имя',
          enabled: false,
        ),
        const SizedBox(height: 16),
        _EditTextField(
          controller: _secondNameController,
          label: 'Отчество',
          hintText: 'Введите отчество',
        ),
        const SizedBox(height: 16),
        _EditTextField(
          controller: _lastNameController,
          label: 'Фамилия',
          hintText: 'Введите фамилию',
        ),
      ],
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color ?? AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Остальные классы остаются без изменений, но добавлю стилизованные диалоговые окна:

class _CreateProjectDialog extends StatefulWidget {
  final Function(String) onCreateProject;

  const _CreateProjectDialog({
    Key? key,
    required this.onCreateProject,
  }) : super(key: key);

  @override
  __CreateProjectDialogState createState() => __CreateProjectDialogState();
}

class __CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await widget.onCreateProject(_nameController.text);
        Navigator.of(context).pop();
      } catch (e) {
        // Ошибка обрабатывается в родительском виджете
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _closeDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Создать проект',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onPressed: () => _closeDialog(context),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Название проекта',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        offset: Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Введите название проекта',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите название проекта';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _closeDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Отмена',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isLoading ? null : () => _submit(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Создать',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
    );
  }
}

class _DeleteProjectDialog extends StatelessWidget {
  final String projectName;
  final VoidCallback onDelete;

  const _DeleteProjectDialog({
    Key? key,
    required this.projectName,
    required this.onDelete,
  }) : super(key: key);

  void _closeDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Удаление проекта',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () => _closeDialog(context),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Вы уверены, что хотите удалить проект "$projectName"?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _closeDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Отмена',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Удалить',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
    );
  }
}

class _EditTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool enabled;

  const _EditTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                offset: Offset(0, 2),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              color: enabled ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}

class _MyProjectsSection extends StatelessWidget {
  final List<ProjectResponse> projects;
  final VoidCallback onCreateProject;
  final Function(int, String) onDeleteProject;

  const _MyProjectsSection({
    Key? key,
    required this.projects,
    required this.onCreateProject,
    required this.onDeleteProject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Мои проекты',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onCreateProject,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textOnPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            const _EmptyState(
              icon: Icons.folder_open,
              message: 'Нет проектов',
            )
          else
            Column(
              children: projects
                  .map((project) => _ProjectItem(
                        project: project,
                        onDelete: () =>
                            onDeleteProject(project.id, project.name),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ProjectItem extends StatelessWidget {
  final ProjectResponse project;
  final VoidCallback onDelete;

  const _ProjectItem({
    Key? key,
    required this.project,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              project.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowLight,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Material(
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTasksSection extends StatelessWidget {
  final List<TaskResponse> tasks;

  const _MyTasksSection({
    Key? key,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Мои задачи',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            const _EmptyState(
              icon: Icons.task,
              message: 'Нет задач',
            )
          else
            Column(
              children: tasks.map((task) => _TaskItem(task: task)).toList(),
            ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final TaskResponse task;

  const _TaskItem({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (task.assignBy.isNotEmpty)
            Row(
              children: [
                if (task.assignByImage != null)
                  ClipOval(
                    child: Image.memory(
                      base64Decode(task.assignByImage!),
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _defaultAvatar(20);
                      },
                    ),
                  )
                else
                  _defaultAvatar(20),
                const SizedBox(width: 8),
                Text(
                  task.assignBy,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Можно взять в работу',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    Key? key,
    required this.icon,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
