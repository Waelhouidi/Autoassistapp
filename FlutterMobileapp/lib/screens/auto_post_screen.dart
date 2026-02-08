import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../services/post_service.dart';
import '../services/platform_service.dart';
import 'platform_connection_screen.dart';

class AutoPostScreen extends StatefulWidget {
  const AutoPostScreen({super.key});

  @override
  State<AutoPostScreen> createState() => _AutoPostScreenState();
}

class _AutoPostScreenState extends State<AutoPostScreen>
    with TickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final Set<String> _selectedPlatforms = {};
  String _enhancedContent = '';
  String? _currentPostId;
  bool _isEnhancing = false;
  bool _isPublishing = false;
  bool _isScheduling = false;
  bool _showResult = false;

  // Scheduling
  DateTime? _scheduledDateTime;
  bool _scheduleMode = false;

  // Platform connection status
  Map<String, PlatformConnection> _platformStatus = {};
  bool _loadingPlatforms = true;

  late AnimationController _gradientController;
  late AnimationController _orbController;
  late AnimationController _cardController;
  late AnimationController _pulseController;
  late Animation<double> _cardAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPlatformStatus();
  }

  Future<void> _loadPlatformStatus() async {
    setState(() => _loadingPlatforms = true);
    try {
      final status = await PlatformService.getPlatformStatus();
      setState(() {
        _platformStatus = status;
        _loadingPlatforms = false;
      });
    } catch (e) {
      setState(() => _loadingPlatforms = false);
    }
  }

  void _initAnimations() {
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _cardController.forward();
  }

  Future<void> _enhanceContent() async {
    if (_contentController.text.trim().isEmpty) {
      _showToast('Please write something first! ✍️', isError: true);
      return;
    }

    if (_selectedPlatforms.isEmpty) {
      _showToast('Pick at least one platform! 🎯', isError: true);
      return;
    }

    setState(() {
      _isEnhancing = true;
      _showResult = false;
    });

    try {
      final result = await PostService.enhanceContent(
        _contentController.text.trim(),
        _selectedPlatforms.toList(),
      );

      setState(() {
        _enhancedContent =
            result['improvedContent'] ?? result['enhanced_content'] ?? '';
        _currentPostId = result['postId'];
        _showResult = true;
      });
      _showToast('✨ Content enhanced perfectly!');
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      setState(() {
        _isEnhancing = false;
      });
    }
  }

  Future<void> _publishContent() async {
    final content = _enhancedContent.isNotEmpty
        ? _enhancedContent
        : _contentController.text.trim();

    if (content.isEmpty) {
      _showToast('Nothing to publish yet! 📝', isError: true);
      return;
    }

    if (_selectedPlatforms.isEmpty) {
      _showToast('Select platforms first! 🎯', isError: true);
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final result = await PostService.publishContent(
        content,
        _selectedPlatforms.toList(),
      );

      if (result['success'] == true) {
        _showToast('🎉 Published successfully!');
        HapticFeedback.heavyImpact();

        // Reset form after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _contentController.clear();
              _enhancedContent = '';
              _showResult = false;
              _selectedPlatforms.clear();
            });
          }
        });
      } else {
        _showToast('Publishing failed: ${result['message'] ?? 'Unknown error'}',
            isError: true);
      }
    } catch (e) {
      _showToast('Publishing failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: AppSpacing.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyBold.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 3),
        elevation: AppSpacing.elevationLg,
      ),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _orbController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // 💜 Beautiful Purple Gradient Background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF0C1120), // Deep Navy
                            const Color(0xFF161B2C), // Surface Navy
                            const Color(0xFF1E2638), // Muted Navy
                            const Color(0xFF0C1120),
                          ]
                        : [
                            const Color(0xFF9370DB), // Medium Purple
                            const Color(0xFF7B2CBF), // Deep Purple
                            const Color(0xFFBA55D3), // Medium Orchid
                            const Color(0xFFDA70D6), // Orchid
                          ]
                            .map((c) => Color.lerp(c, Colors.white, 0.1)!)
                            .toList(),
                    stops: const [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
              );
            },
          ),

          // Animated Orbs
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildOrb(
                    top: -100 + (80 * _orbController.value),
                    left: -100 + (50 * _orbController.value),
                    width: 500,
                    color: isDark
                        ? const Color(0xFF3A82FF).withValues(alpha: 0.2)
                        : const Color(0xFF9370DB),
                  ),
                  _buildOrb(
                    bottom: -120 + (60 * (1 - _orbController.value)),
                    right: -120 + (70 * (1 - _orbController.value)),
                    width: 450,
                    color: isDark
                        ? const Color(0xFF0056D6).withValues(alpha: 0.2)
                        : const Color(0xFFBA55D3),
                  ),
                  _buildOrb(
                    top: MediaQuery.of(context).size.height * 0.35 +
                        (50 * _orbController.value),
                    right: -80 + (40 * (1 - _orbController.value)),
                    width: 380,
                    color: isDark
                        ? const Color(0xFF3A82FF).withValues(alpha: 0.1)
                        : const Color(0xFFDDA0DD),
                  ),
                  _buildOrb(
                    top: 80 + (40 * (1 - _orbController.value)),
                    right: 50 + (30 * _orbController.value),
                    width: 320,
                    color: isDark
                        ? const Color(0xFF66A1FF).withValues(alpha: 0.1)
                        : const Color(0xFF8A2BE2),
                  ),
                ],
              );
            },
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FadeTransition(
                opacity: _cardAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_cardAnimation),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _buildHeader(isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildMainCard(isDark),
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

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double width,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: width,
        height: width,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Pulsing Logo
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFBA55D3),
                      Color(0xFF9370DB),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBA55D3).withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/defaults/app_logo.png',
                  width: 70,
                  height: 70,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.auto_awesome_rounded,
                    size: AppSpacing.iconXl,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        // Title with Sparkle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFF3E5F5)],
              ).createShader(bounds),
              child: const Text(
                'AutoAssist',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              '✨',
              style: TextStyle(fontSize: 32),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Text(
            '💜 Create amazing posts with AI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .cardColor
                .withValues(alpha: isDark ? 0.9 : 0.98),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: Column(
            children: [
              // Gradient Top Bar
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF9370DB),
                      Color(0xFFBA55D3),
                      Color(0xFFDDA0DD),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContentInput(isDark),
                    const SizedBox(height: 28),
                    _buildPlatformSelector(isDark),
                    const SizedBox(height: 28),
                    _buildActionButtons(),
                    if (_showResult) ...[
                      const SizedBox(height: 28),
                      _buildResultSection(isDark),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9370DB), Color(0xFFBA55D3)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBA55D3).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'YOUR IDEA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            const Text(
              '✍️',
              style: TextStyle(fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.1)
                : const Color(0xFF9370DB).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : const Color(0xFF9370DB).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9370DB).withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: _contentController,
            maxLines: 5,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color:
                  isDark ? AppColors.textPrimaryDark : const Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              hintText:
                  'Share your thoughts... ✨\nOur AI will make it amazing! 💜',
              hintStyle: TextStyle(
                color: const Color(0xFF6B7280).withValues(alpha: 0.6),
                fontSize: 15,
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSelector(bool isDark) {
    final platforms = [
      {
        'name': 'Twitter',
        'icon': '🐦',
        'emoji': '💙',
        'color': const Color(0xFF1DA1F2)
      },
      {
        'name': 'LinkedIn',
        'icon': '💼',
        'emoji': '💼',
        'color': const Color(0xFF0A66C2)
      },
      {
        'name': 'Facebook',
        'icon': '📘',
        'emoji': '👍',
        'color': const Color(0xFF1877F2)
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBA55D3), Color(0xFFDDA0DD)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBA55D3).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.share_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'PLATFORMS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            const Text(
              '🎯',
              style: TextStyle(fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: platforms.map((platform) {
            final isSelected =
                _selectedPlatforms.contains(platform['name'] as String);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildPlatformCard(
                  platform['name'] as String,
                  platform['icon'] as String,
                  platform['emoji'] as String,
                  platform['color'] as Color,
                  isSelected,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlatformCard(
      String name, String icon, String emoji, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isSelected) {
            _selectedPlatforms.remove(name);
          } else {
            _selectedPlatforms.add(name);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              isSelected ? emoji : icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Enhance Button
        _buildActionButton(
          label: _isEnhancing ? 'Enhancing...' : 'Enhance with AI',
          icon: Icons.auto_awesome_rounded,
          onTap: _isEnhancing ? null : _enhanceContent,
          gradient: const LinearGradient(
            colors: [Color(0xFF9370DB), Color(0xFFBA55D3)],
          ),
          isLoading: _isEnhancing,
        ),
        const SizedBox(height: 16),

        // Schedule Toggle
        _buildScheduleSection(isDark),
        const SizedBox(height: 16),

        // Publish/Schedule Button
        _buildActionButton(
          label: _isPublishing
              ? 'Publishing...'
              : (_isScheduling
                  ? 'Scheduling...'
                  : (_scheduleMode && _scheduledDateTime != null
                      ? 'Schedule for Later'
                      : 'Publish Now')),
          icon: _scheduleMode && _scheduledDateTime != null
              ? Icons.schedule_send_rounded
              : Icons.send_rounded,
          onTap: (_isPublishing || _isScheduling)
              ? null
              : _handlePublishOrSchedule,
          gradient: LinearGradient(
            colors: _scheduleMode && _scheduledDateTime != null
                ? [const Color(0xFF3498DB), const Color(0xFF2980B9)]
                : [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
          ),
          isLoading: _isPublishing || _isScheduling,
        ),

        const SizedBox(height: 24),

        // Connect Platforms Button
        _buildConnectPlatformsButton(isDark),
      ],
    );
  }

  Widget _buildScheduleSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _scheduleMode
              ? const Color(0xFF3498DB).withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _scheduleMode
                        ? [const Color(0xFF3498DB), const Color(0xFF2980B9)]
                        : [Colors.grey.shade400, Colors.grey.shade500],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule for Later',
                      style: AppTypography.bodyBold.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Set a specific date and time',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _scheduleMode,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _scheduleMode = value;
                    if (!value) _scheduledDateTime = null;
                  });
                },
                activeColor: const Color(0xFF3498DB),
              ),
            ],
          ),

          // Date/Time Picker
          if (_scheduleMode) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3498DB).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF3498DB),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _scheduledDateTime != null
                            ? _formatDateTime(_scheduledDateTime!)
                            : 'Tap to select date & time',
                        style: TextStyle(
                          color: _scheduledDateTime != null
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey,
                          fontWeight: _scheduledDateTime != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectPlatformsButton(bool isDark) {
    final connectedCount =
        _platformStatus.values.where((p) => p.connected).length;

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PlatformConnectionScreen(),
          ),
        );
        // Reload platform status after returning
        _loadPlatformStatus();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect Your Accounts',
                    style: AppTypography.bodyBold.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _loadingPlatforms
                        ? 'Loading...'
                        : '$connectedCount platform${connectedCount != 1 ? 's' : ''} connected',
                    style: AppTypography.caption.copyWith(
                      color: connectedCount > 0
                          ? AppColors.success
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    // Pick Date
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF3498DB),
                ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    // Pick Time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledDateTime ?? now.add(const Duration(hours: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF3498DB),
                ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(DateTime.now())) {
      _showToast('Please select a future date/time', isError: true);
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _scheduledDateTime = scheduled);
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $amPm';
  }

  Future<void> _handlePublishOrSchedule() async {
    final content = _enhancedContent.isNotEmpty
        ? _enhancedContent
        : _contentController.text.trim();

    if (content.isEmpty) {
      _showToast('Nothing to publish yet! 📝', isError: true);
      return;
    }

    if (_selectedPlatforms.isEmpty) {
      _showToast('Select platforms first! 🎯', isError: true);
      return;
    }

    // Check if scheduling
    if (_scheduleMode) {
      if (_scheduledDateTime == null) {
        _showToast('Please select a date and time! 📅', isError: true);
        return;
      }
      await _scheduleContent();
    } else {
      await _publishContent();
    }
  }

  Future<void> _scheduleContent() async {
    setState(() => _isScheduling = true);

    try {
      final content = _enhancedContent.isNotEmpty
          ? _enhancedContent
          : _contentController.text.trim();

      final result = await PostService.publishContent(
        content,
        _selectedPlatforms.toList(),
        postId: _currentPostId,
        scheduledAt: _scheduledDateTime!.toIso8601String(),
        publishNow: false,
      );

      if (result['success'] == true) {
        _showToast('📅 Scheduled for ${_formatDateTime(_scheduledDateTime!)}');
        HapticFeedback.heavyImpact();

        // Reset form after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _contentController.clear();
              _enhancedContent = '';
              _currentPostId = null;
              _showResult = false;
              _selectedPlatforms.clear();
              _scheduleMode = false;
              _scheduledDateTime = null;
            });
          }
        });
      } else {
        _showToast('Scheduling failed: ${result['message'] ?? 'Unknown error'}',
            isError: true);
      }
    } catch (e) {
      _showToast('Scheduling failed: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isScheduling = false);
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required Gradient gradient,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: onTap != null
            ? gradient
            : LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade500],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: (gradient as LinearGradient)
                      .colors[0]
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 20,
                color: Color(0xFF9370DB),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ENHANCED RESULT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF9370DB).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF9370DB).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _enhancedContent,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _enhancedContent));
                      _showToast('Copied to clipboard!');
                    },
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Color(0xFF9370DB),
                    ),
                    label: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Color(0xFF9370DB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
