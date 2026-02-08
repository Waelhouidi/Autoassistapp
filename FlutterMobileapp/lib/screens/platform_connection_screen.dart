import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async'; // Add this for Timer
import 'package:url_launcher/url_launcher.dart'; // Add this
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../services/platform_service.dart';

/// Platform Connection Screen
/// Allows users to connect their Twitter and LinkedIn accounts for publishing
class PlatformConnectionScreen extends StatefulWidget {
  const PlatformConnectionScreen({super.key});

  @override
  State<PlatformConnectionScreen> createState() =>
      _PlatformConnectionScreenState();
}

class _PlatformConnectionScreenState extends State<PlatformConnectionScreen>
    with TickerProviderStateMixin {
  Map<String, PlatformConnection> _platforms = {};
  bool _isLoading = true;
  String? _connectingPlatform;

  late AnimationController _gradientController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPlatformStatus();
  }

  void _initAnimations() {
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );

    _cardController.forward();
  }

  Future<void> _loadPlatformStatus() async {
    setState(() => _isLoading = true);

    try {
      final status = await PlatformService.getPlatformStatus();
      setState(() {
        _platforms = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('Failed to load platforms: ${e.toString()}', isError: true);
    }
  }

  Future<void> _connectPlatform(String platform) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Connection Method',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security, color: AppColors.primary),
              ),
              title: const Text('OAuth (Browser)'),
              subtitle: const Text('Connect safely via official login page'),
              onTap: () => Navigator.pop(context, 'oauth'),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.login_rounded, color: AppColors.secondary),
              ),
              title: const Text('Direct Login'),
              subtitle: const Text('Use email/username and password'),
              onTap: () => Navigator.pop(context, 'credentials'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );

    if (method == null) return;

    if (method == 'oauth') {
      _startOAuthFlow(platform);
    } else {
      _showCredentialsDialog(platform);
    }
  }

  Timer? _pollTimer;

  // New _startOAuthFlow with automatic connection
  Future<void> _startOAuthFlow(String platform) async {
    setState(() => _connectingPlatform = platform);

    try {
      final authUrl = await PlatformService.initiateAuth(platform);

      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            _showWaitingDialog(platform);
            _startPolling(platform);
          }
        } else {
          _showToast('Cannot launch URL: $authUrl', isError: true);
        }
      } else {
        _showToast('Failed to get authorization URL', isError: true);
      }
    } catch (e) {
      _showToast('Connection failed: ${e.toString()}', isError: true);
    } finally {
      setState(() => _connectingPlatform = null);
    }
  }

  void _startPolling(String platform) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final isConnected = await PlatformService.isConnected(platform);
        if (isConnected) {
          timer.cancel();
          if (mounted) {
            Navigator.of(context).pop(); // Close waiting dialog
            _showToast('$platform connected successfully! 🎉');
            _loadPlatformStatus();
          }
        }
      } catch (e) {
        // Silent error, continue polling
      }
    });

    // Timeout after 2 minutes
    Future.delayed(const Duration(minutes: 2), () {
      if (_pollTimer?.isActive ?? false) {
        _pollTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          _showToast('Connection timed out', isError: true);
        }
      }
    });
  }

  void _showWaitingDialog(String platform) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text('Connecting to $platform'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Please complete the authorization in your browser.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'The app will update automatically once connected.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCredentialsDialog(String platform) {
    final platformName =
        platform[0].toUpperCase() + platform.substring(1).toLowerCase();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          title: Row(
            children: [
              Icon(
                Icons.login_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconLg,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Direct Login: $platformName',
                style: AppTypography.h3,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your $platformName credentials:',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email or Username',
                    hintText: 'your@email.com',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Note: Your credentials are encrypted and used only for publishing.',
                  style: AppTypography.caption.copyWith(color: Colors.orange),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text;

                if (email.isEmpty || password.isEmpty) {
                  _showToast('Email and password are required', isError: true);
                  return;
                }

                Navigator.of(context).pop();
                await _completeCredentialsConnect(platform, email, password);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child:
                  const Text('Connect', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeCredentialsConnect(
      String platform, String email, String password) async {
    setState(() => _connectingPlatform = platform);
    try {
      final success = await PlatformService.connectWithCredentials(
        platform: platform,
        email: email,
        password: password,
      );

      if (success) {
        _showToast('$platform connected with credentials! 🎉');
        _loadPlatformStatus();
      } else {
        _showToast('Failed to connect $platform', isError: true);
      }
    } catch (e) {
      _showToast('Connection failed: ${e.toString()}', isError: true);
    } finally {
      setState(() => _connectingPlatform = null);
    }
  }

  Future<void> _disconnectPlatform(String platform) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Platform'),
        content: Text('Are you sure you want to disconnect $platform?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child:
                const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await PlatformService.disconnect(platform);
        if (success) {
          _showToast('$platform disconnected');
          _loadPlatformStatus();
        }
      } catch (e) {
        _showToast('Failed to disconnect: ${e.toString()}', isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
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
                            const Color(0xFF0C1120),
                            const Color(0xFF161B2C),
                            const Color(0xFF1E2638),
                          ]
                        : [
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                            const Color(0xFFf093fb),
                          ],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Text(
                          'Connect Platforms',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _loadPlatformStatus,
                        icon: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: FadeTransition(
                    opacity: _cardAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_cardAnimation),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : _buildPlatformList(isDark),
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

  Widget _buildPlatformList(bool isDark) {
    final platformConfigs = [
      {
        'name': 'twitter',
        'displayName': 'Twitter / X',
        'icon': '🐦',
        'color': const Color(0xFF1DA1F2),
        'description': 'Post tweets to your Twitter account',
      },
      {
        'name': 'linkedin',
        'displayName': 'LinkedIn',
        'icon': '💼',
        'color': const Color(0xFF0A66C2),
        'description': 'Share posts to your LinkedIn profile',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
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
                          const SizedBox(height: 4),
                          Text(
                            'Link your social media accounts to publish posts directly from the app',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Platform Cards
          ...platformConfigs.map((config) {
            final platformName = config['name'] as String;
            final isConnected = _platforms[platformName]?.connected ?? false;
            final profile = _platforms[platformName]?.profile;
            final isConnecting = _connectingPlatform == platformName;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildPlatformCard(
                platformName: platformName,
                displayName: config['displayName'] as String,
                icon: config['icon'] as String,
                color: config['color'] as Color,
                description: config['description'] as String,
                isConnected: isConnected,
                profile: profile,
                isConnecting: isConnecting,
                isDark: isDark,
              ),
            );
          }),

          const SizedBox(height: AppSpacing.xl),

          // Additional Info
          Center(
            child: Text(
              'Your credentials are stored securely and encrypted',
              style: AppTypography.small.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard({
    required String platformName,
    required String displayName,
    required String icon,
    required Color color,
    required String description,
    required bool isConnected,
    required PlatformProfile? profile,
    required bool isConnecting,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isConnected
                  ? color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              width: isConnected ? 2 : 1,
            ),
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.h3.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (isConnected) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Connected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isConnected && profile?.username != null
                              ? '@${profile!.username}'
                              : description,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  if (isConnecting)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  else if (isConnected)
                    IconButton(
                      onPressed: () => _disconnectPlatform(platformName),
                      icon: Icon(
                        Icons.link_off_rounded,
                        color: AppColors.error,
                      ),
                      tooltip: 'Disconnect',
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _connectPlatform(platformName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: const Text('Connect'),
                    ),
                ],
              ),

              // Connected Profile Info
              if (isConnected && profile != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      if (profile.avatarUrl != null)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(profile.avatarUrl!),
                        )
                      else
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.3),
                          child: Text(
                            (profile.name ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name ?? 'User',
                              style: AppTypography.bodyBold.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (profile.username != null)
                              Text(
                                '@${profile.username}',
                                style: AppTypography.caption.copyWith(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified,
                        color: color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
