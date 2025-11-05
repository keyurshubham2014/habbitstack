import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/user_provider.dart';
import '../../providers/logs_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/streaks_provider.dart';
import '../../models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.headline()),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryText),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 80,
                    color: AppColors.neutralGray,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No user found',
                    style: AppTextStyles.title(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please create a user profile to continue',
                    style: AppTextStyles.body().copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Initialize controllers with current user data
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name;
          }
          if (_emailController.text.isEmpty && user.email != null) {
            _emailController.text = user.email!;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(user),

                const SizedBox(height: 16),

                // Edit Form (if editing)
                if (_isEditing) _buildEditForm(user),

                // Stats Cards
                if (!_isEditing) ...[
                  _buildStatsSection(),
                  const SizedBox(height: 16),
                  _buildAccountSection(user),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.softRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: AppTextStyles.title(),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.gentleTeal,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: AppTextStyles.headline().copyWith(
                fontSize: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: AppTextStyles.headline(),
          ),

          // Email
          if (user.email != null && user.email!.isNotEmpty)
            Text(
              user.email!,
              style: AppTextStyles.body().copyWith(
                color: AppColors.secondaryText,
              ),
            ),

          const SizedBox(height: 8),

          // Premium Badge
          if (user.premiumStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warningAmber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 16,
                    color: AppColors.warningAmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Premium Member',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.warningAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm(User user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Profile',
              style: AppTextStyles.title(),
            ),
            const SizedBox(height: 20),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Invalid email format';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _nameController.text = user.name;
                        _emailController.text = user.email ?? '';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.neutralGray),
                    ),
                    child: Text('Cancel', style: AppTextStyles.body()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveProfile(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warmCoral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Save', style: AppTextStyles.body()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final logsAsync = ref.watch(logsNotifierProvider);
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final streaksAsync = ref.watch(currentUserStreaksProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Activity',
            style: AppTextStyles.title(),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Total Logs
                  logsAsync.when(
                    data: (logs) => _buildStatRow(
                      icon: Icons.check_circle,
                      label: 'Total Activities Logged',
                      value: logs.length.toString(),
                      color: AppColors.successGreen,
                    ),
                    loading: () => _buildStatRowLoading('Total Activities Logged'),
                    error: (_, __) => _buildStatRow(
                      icon: Icons.check_circle,
                      label: 'Total Activities Logged',
                      value: '0',
                      color: AppColors.successGreen,
                    ),
                  ),
                  const Divider(height: 24),

                  // Total Habits
                  habitsAsync.when(
                    data: (habits) => _buildStatRow(
                      icon: Icons.track_changes,
                      label: 'Habits Tracked',
                      value: habits.length.toString(),
                      color: AppColors.gentleTeal,
                    ),
                    loading: () => _buildStatRowLoading('Habits Tracked'),
                    error: (_, __) => _buildStatRow(
                      icon: Icons.track_changes,
                      label: 'Habits Tracked',
                      value: '0',
                      color: AppColors.gentleTeal,
                    ),
                  ),
                  const Divider(height: 24),

                  // Longest Streak
                  streaksAsync.when(
                    data: (streaks) {
                      final longestStreak = streaks.isEmpty
                          ? 0
                          : streaks
                              .map((s) => s.currentStreak)
                              .reduce((a, b) => a > b ? a : b);
                      return _buildStatRow(
                        icon: Icons.local_fire_department,
                        label: 'Longest Streak',
                        value: '$longestStreak days',
                        color: AppColors.warmCoral,
                      );
                    },
                    loading: () => _buildStatRowLoading('Longest Streak'),
                    error: (_, __) => _buildStatRow(
                      icon: Icons.local_fire_department,
                      label: 'Longest Streak',
                      value: '0 days',
                      color: AppColors.warmCoral,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.title().copyWith(
            fontSize: 20,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRowLoading(String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.neutralGray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(),
          ),
        ),
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _buildAccountSection(User user) {
    final memberSince = _formatMemberSince(user.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: AppTextStyles.title(),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Member Since',
                    value: memberSince,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.workspace_premium,
                    label: 'Account Type',
                    value: user.premiumStatus ? 'Premium' : 'Free',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepBlue, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body().copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  String _formatMemberSince(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
  }

  Future<void> _saveProfile(User user) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedUser = user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );

    try {
      await ref.read(userNotifierProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }
}
