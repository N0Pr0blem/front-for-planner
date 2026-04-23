// lib/screen/profile/widgets/pricing_section.dart
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class PricingSection extends StatelessWidget {
  final String currentPlan;
  final int aiRequestsUsed;
  final int aiRequestsLimit;

  const PricingSection({
    Key? key,
    required this.currentPlan,
    this.aiRequestsUsed = 0,
    this.aiRequestsLimit = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Тарифные планы',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Выберите подходящий план',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Прогресс ИИ-запросов (только для Basic и Pro)
          if (currentPlan != 'unlimited') ...[
            _AiUsageCard(
              used: aiRequestsUsed,
              limit: aiRequestsLimit,
            ),
            const SizedBox(height: 32),
          ],

          // Сетка тарифов
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                childAspectRatio: isWide ? 0.85 : 1.1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _PricingCard(
                    title: 'Обычный',
                    price: '0\$',
                    period: 'в месяц',
                    features: [
                      '3 запроса к ИИ в день',
                      'Базовые функции',
                      'Поддержка по email',
                      '1 пользователь',
                    ],
                    isCurrent: currentPlan == 'basic',
                    isPopular: false,
                    icon: Icons.person,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.textHint.withOpacity(0.1),
                        AppColors.textHint.withOpacity(0.05),
                      ],
                    ),
                    onSelect: () {},
                  ),
                  _PricingCard(
                    title: 'Продвинутый',
                    price: '5\$',
                    period: 'в месяц',
                    features: [
                      '25 запросов к ИИ в день',
                      'Приоритетная поддержка',
                      'Расширенная аналитика',
                      'До 5 пользователей',
                      'Интеграции API',
                    ],
                    isCurrent: currentPlan == 'pro',
                    isPopular: true,
                    icon: Icons.star,
                    gradient: AppGradients.primaryButton,
                    onSelect: () {},
                  ),
                  _PricingCard(
                    title: 'Безлимит',
                    price: '10\$',
                    period: 'в месяц',
                    features: [
                      'Безлимитные запросы к ИИ',
                      'VIP поддержка 24/7',
                      'Полный доступ ко всем функциям',
                      'Безлимит пользователей',
                      'Приоритетные обновления',
                      'Персональный менеджер',
                    ],
                    isCurrent: currentPlan == 'unlimited',
                    isPopular: false,
                    icon: Icons.auto_awesome,
                    gradient: AppGradients.primaryButton,
                    onSelect: () {},
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Карточка использования ИИ
class _AiUsageCard extends StatelessWidget {
  final int used;
  final int limit;

  const _AiUsageCard({
    required this.used,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (used / limit).clamp(0.0, 1.0);
    final isNearLimit = percentage >= 0.8;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isNearLimit
                ? Colors.orange.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            isNearLimit
                ? Colors.orange.withOpacity(0.05)
                : AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNearLimit
              ? Colors.orange.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isNearLimit
                      ? Colors.orange.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: isNearLimit ? Colors.orange : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ИИ-запросы сегодня',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$used из $limit использовано',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              if (isNearLimit) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Лимит скоро',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                isNearLimit ? Colors.orange : AppColors.primary,
              ),
            ),
          ),
          if (isNearLimit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Обновите тариф для больших лимитов',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Карточка тарифа
class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onSelect;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrent,
    required this.isPopular,
    required this.icon,
    required this.gradient,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary
              : isPopular
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.cardBorder.withOpacity(0.3),
          width: isCurrent ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: -4,
            )
          else
            BoxShadow(
              color: AppColors.shadowLight.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: -2,
            ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Бейдж текущего/популярного плана
                if (isCurrent || isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isCurrent
                          ? AppGradients.primaryButton
                          : LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.2),
                                Colors.orange.withOpacity(0.1),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCurrent ? Icons.check_circle : Icons.whatshot,
                          color: isCurrent ? Colors.white : Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCurrent ? 'Текущий план' : 'Популярный',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? Colors.white : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isCurrent && !isPopular) const SizedBox(height: 32),
                const SizedBox(height: 16),

                // Иконка
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isPopular || isCurrent
                        ? Colors.white
                        : AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Название и цена
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isPopular || isCurrent
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Разделитель
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.cardBorder,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Фичи
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: (isPopular || isCurrent)
                                  ? AppColors.primary.withOpacity(0.2)
                                  : AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: (isPopular || isCurrent)
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.7),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                const Spacer(),
                const SizedBox(height: 16),

                // Кнопка
                if (!isCurrent)
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isPopular
                          ? AppGradients.primaryButton
                          : LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.05),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPopular
                            ? Colors.transparent
                            : AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onSelect,
                        child: Center(
                          child: Text(
                            isPopular ? 'Выбрать план' : 'Перейти на этот план',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isPopular
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
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