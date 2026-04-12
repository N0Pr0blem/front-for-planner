// lib/screen/profile/widgets/profile_section.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../dto/user/user_response.dart';
import '../../../service/main_service.dart';
import '../../../theme/colors.dart';

class ProfileSection extends StatefulWidget {
  final UserResponse user;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final VoidCallback onCancelEdit;
  final VoidCallback onProfileUpdated;
  final bool isMobile;
  final int projectsCount;
  final int tasksCount;

  const ProfileSection({
    Key? key,
    required this.user,
    required this.isEditing,
    required this.onEditToggle,
    required this.onCancelEdit,
    required this.onProfileUpdated,
    this.isMobile = false,
    required this.projectsCount,
    required this.tasksCount,
  }) : super(key: key);

  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  late TextEditingController _firstNameController;
  late TextEditingController _secondNameController;
  late TextEditingController _lastNameController;
  PlatformFile? _pickedFile;
  Uint8List? _imageBytes;

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
        PlatformFile file = result.files.first;
        Uint8List? imageBytes;
        
        if (file.bytes != null) {
          imageBytes = file.bytes;
        } else if (file.path != null) {
          File imageFile = File(file.path!);
          if (await imageFile.exists()) {
            imageBytes = await imageFile.readAsBytes();
          }
        }

        if (imageBytes == null || imageBytes.isEmpty) {
          throw Exception('Не удалось получить данные файла');
        }

        setState(() {
          _pickedFile = file;
          _imageBytes = imageBytes;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Изображение "${file.name}" выбрано'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
        await MainService().updateProfileWithImage(
          secondName: _secondNameController.text,
          lastName: _lastNameController.text,
          fileBytes: _imageBytes!,
          fileName: _pickedFile!.name,
          mimeType: _pickedFile!.extension ?? 'image/jpeg',
        );
      } else {
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

  Widget _buildAvatar({double size = 120}) {
    if (_imageBytes != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _defaultAvatar(size),
          ),
        ),
      );
    }

    return widget.user.hasProfileImage
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.memory(
                base64Decode(widget.user.profileImage!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _defaultAvatar(size),
              ),
            ),
          )
        : _defaultAvatar(size);
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.3),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // lib/screen/profile/widgets/profile_section.dart
// В методе build заменяем Container на:

@override
Widget build(BuildContext context) {
  return Container(
    // Убираем width: double.infinity, он и так будет растягиваться
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowLight.withOpacity(0.5),
          offset: const Offset(0, 8),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isEditing) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Профиль',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Редактировать',
                onTap: widget.onEditToggle,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildProfileView(),
        ] else
          _buildProfileEdit(),
      ],
    ),
  );
}

  Widget _buildProfileView() {
    if (widget.isMobile) {
      return Column(
        children: [
          Center(child: _buildAvatar(size: 140)),
          const SizedBox(height: 24),
          Text(
            widget.user.displayName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '@${widget.user.username}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('Проектов', widget.projectsCount, Icons.folder, AppColors.primary),
              const SizedBox(width: 12),
              _buildStatCard('Задач', widget.tasksCount, Icons.task_alt, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.email_outlined,
                  'Email',
                  widget.user.username,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.work_outline,
                  'Тарифный план',
                  'Обычный',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Дата регистрации',
                  widget.user.registrationDate != null
                      ? _formatDate(widget.user.registrationDate!)
                      : 'Не указана',
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(size: 160),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '@${widget.user.username}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatCard('Проектов', widget.projectsCount, Icons.folder, AppColors.primary),
                      const SizedBox(width: 16),
                      _buildStatCard('Задач', widget.tasksCount, Icons.task_alt, Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange.withOpacity(0.1),
                                Colors.orange.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.workspace_premium, color: Colors.orange, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Обычный',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Тариф',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.email_outlined,
                  'Email',
                  widget.user.username,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.cardBorder.withOpacity(0.5),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: _buildInfoRow(
                    Icons.calendar_today_outlined,
                    'Дата регистрации',
                    widget.user.registrationDate != null
                        ? _formatDate(widget.user.registrationDate!)
                        : 'Не указана',
                  ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Редактирование профиля',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Stack(
                  children: [
                    _buildAvatar(size: 140),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera, color: Colors.white, size: 32),
                            SizedBox(height: 4),
                            Text(
                              'Изменить фото',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                children: [
                  _EditTextField(
                    controller: _firstNameController,
                    label: 'Имя',
                    hintText: 'Введите имя',
                    enabled: false,
                    isMobile: widget.isMobile,
                  ),
                  const SizedBox(height: 16),
                  _EditTextField(
                    controller: _secondNameController,
                    label: 'Отчество',
                    hintText: 'Введите отчество',
                    isMobile: widget.isMobile,
                  ),
                  const SizedBox(height: 16),
                  _EditTextField(
                    controller: _lastNameController,
                    label: 'Фамилия',
                    hintText: 'Введите фамилию',
                    isMobile: widget.isMobile,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancelEdit,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Сохранить изменения'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
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
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryButton,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _EditTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool enabled;
  final bool isMobile;

  const _EditTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.enabled = true,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 6,
                spreadRadius: -2,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: TextStyle(
              color: enabled ? AppColors.textPrimary : AppColors.textHint,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}