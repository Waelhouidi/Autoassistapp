import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/todo_provider.dart';
import 'scheduled_posts_screen.dart';
import 'platform_connection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<TodoProvider>().loadData(),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeSection(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickStats(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFeatureGrid(context),
                  // Add bottom padding for better scroll experience
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/defaults/app_logo.png',
              height: 60,
              width: 60,
              errorBuilder: (context, error, stackTrace) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'AutoAssist',
              style: AppTypography.h3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, 👋',
          style: AppTypography.h2.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Here\'s what\'s happening today.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        final isLoading = provider.isLoading && stats == null;

        return isLoading
            ? Shimmer.fromColors(
                baseColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
                highlightColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[100]!,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Pending',
                      '${stats?.pending ?? 0}',
                      Icons.checklist_rtl_rounded,
                    ),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _buildStatItem(
                      'In Progress',
                      '${stats?.inProgress ?? 0}',
                      Icons.schedule_rounded,
                    ),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _buildStatItem(
                      'Completed',
                      '${stats?.completed ?? 0}',
                      Icons.done_all_rounded,
                    ),
                  ],
                ),
              );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.h2.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.1,
      children: [
        _FeatureCard(
          title: 'My Tasks',
          imagePath: 'assets/images/defaults/task.png',
          color: AppColors.primary,
          onTap: () {
            // Navigation handled by MainNavigator
          },
        ),
        _FeatureCard(
          title: 'Auto Post',
          imagePath: 'assets/images/defaults/autopost.png',
          color: AppColors.secondary,
          onTap: () {},
        ),
        _FeatureCard(
          title: 'Scheduled',
          icon: Icons.schedule_send_rounded,
          color: const Color(0xFF3498DB),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ScheduledPostsScreen(),
              ),
            );
          },
        ),
        _FeatureCard(
          title: 'Platforms',
          icon: Icons.link_rounded,
          color: const Color(0xFF9B59B6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PlatformConnectionScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String? imagePath;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    this.imagePath,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      width: 32,
                      height: 32,
                      color: color,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image, color: color, size: 32),
                    )
                  : Icon(icon ?? Icons.widgets, color: color, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.bodyBold,
            ),
          ],
        ),
      ),
    );
  }
}
