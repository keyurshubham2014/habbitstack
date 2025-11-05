# Task 22: Accountability Partner Invite System

**Status**: TODO
**Priority**: MEDIUM
**Estimated Time**: 4 hours
**Assigned To**: Claude
**Dependencies**: Task 21 (Authentication & Cloud Sync)
**Completed**: -

---

## Objective

Build a partner invite system that allows users to connect with accountability partners to share habit progress and motivate each other.

## Acceptance Criteria

- [ ] Users can generate unique invite links
- [ ] Invite links expire after 7 days
- [ ] Partners can accept invites via link
- [ ] Maximum 3 accountability partners (free tier)
- [ ] Partner list screen shows all connections
- [ ] Remove/block partner functionality
- [ ] Partner request notifications
- [ ] Privacy settings (what to share)

---

## Step-by-Step Instructions

### 1. Create Partner Model

#### `lib/models/accountability_partner.dart`

```dart
enum PartnerStatus {
  pending,   // Invite sent, not accepted yet
  active,    // Connection accepted and active
  blocked,   // User blocked this partner
}

class AccountabilityPartner {
  final String? id;
  final String userId;           // Current user
  final String partnerId;        // Partner's user ID
  final String? partnerName;     // Cached partner name
  final String? partnerEmail;    // Cached partner email
  final PartnerStatus status;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountabilityPartner({
    this.id,
    required this.userId,
    required this.partnerId,
    this.partnerName,
    this.partnerEmail,
    this.status = PartnerStatus.pending,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'partner_email': partnerEmail,
      'status': status.name,
      'accepted_at': acceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AccountabilityPartner.fromMap(Map<String, dynamic> map) {
    return AccountabilityPartner(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      partnerId: map['partner_id'] as String,
      partnerName: map['partner_name'] as String?,
      partnerEmail: map['partner_email'] as String?,
      status: PartnerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PartnerStatus.pending,
      ),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool get isPending => status == PartnerStatus.pending;
  bool get isActive => status == PartnerStatus.active;
  bool get isBlocked => status == PartnerStatus.blocked;
}
```

### 2. Create Partner Invite Model

#### `lib/models/partner_invite.dart`

```dart
class PartnerInvite {
  final String? id;
  final String inviterId;       // User who created invite
  final String inviteCode;      // Unique invite code
  final DateTime expiresAt;     // 7 days from creation
  final bool isUsed;
  final String? acceptedByUserId;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  PartnerInvite({
    this.id,
    required this.inviterId,
    required this.inviteCode,
    required this.expiresAt,
    this.isUsed = false,
    this.acceptedByUserId,
    this.acceptedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inviter_id': inviterId,
      'invite_code': inviteCode,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'accepted_by_user_id': acceptedByUserId,
      'accepted_at': acceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PartnerInvite.fromMap(Map<String, dynamic> map) {
    return PartnerInvite(
      id: map['id'] as String?,
      inviterId: map['inviter_id'] as String,
      inviteCode: map['invite_code'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      isUsed: map['is_used'] as bool? ?? false,
      acceptedByUserId: map['accepted_by_user_id'] as String?,
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;
}
```

### 3. Update Supabase Schema

Add to your Supabase SQL:

```sql
-- Accountability Partners table
CREATE TABLE IF NOT EXISTS accountability_partners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  partner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  partner_name TEXT,
  partner_email TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, partner_id)
);

-- Partner Invites table
CREATE TABLE IF NOT EXISTS partner_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invite_code TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  accepted_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_partners_user_id ON accountability_partners(user_id);
CREATE INDEX IF NOT EXISTS idx_partners_partner_id ON accountability_partners(partner_id);
CREATE INDEX IF NOT EXISTS idx_partners_status ON accountability_partners(status);
CREATE INDEX IF NOT EXISTS idx_invites_code ON partner_invites(invite_code);
CREATE INDEX IF NOT EXISTS idx_invites_inviter ON partner_invites(inviter_id);

-- RLS Policies
ALTER TABLE accountability_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_invites ENABLE ROW LEVEL SECURITY;

-- Partners: Users can view their own partnerships
CREATE POLICY "Users can view own partnerships"
  ON accountability_partners FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = partner_id);

CREATE POLICY "Users can create partnerships"
  ON accountability_partners FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own partnerships"
  ON accountability_partners FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = partner_id);

CREATE POLICY "Users can delete own partnerships"
  ON accountability_partners FOR DELETE
  USING (auth.uid() = user_id);

-- Invites: Users can view and create their own invites
CREATE POLICY "Users can view own invites"
  ON partner_invites FOR SELECT
  USING (auth.uid() = inviter_id OR id IN (
    SELECT id FROM partner_invites WHERE invite_code = invite_code
  ));

CREATE POLICY "Users can create invites"
  ON partner_invites FOR INSERT
  WITH CHECK (auth.uid() = inviter_id);

CREATE POLICY "Anyone can update invites to accept"
  ON partner_invites FOR UPDATE
  USING (is_used = FALSE AND expires_at > NOW());
```

### 4. Create Partner Service

#### `lib/services/partner_service.dart`

```dart
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/accountability_partner.dart';
import '../models/partner_invite.dart';

class PartnerService {
  final _supabase = Supabase.instance.client;

  /// Generate unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No ambiguous chars
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new partner invite
  Future<PartnerInvite> createInvite(String userId) async {
    // Check if user has reached partner limit
    final existingPartners = await getPartners(userId);
    if (existingPartners.length >= 3) {
      throw Exception('Maximum 3 partners allowed on free tier');
    }

    final inviteCode = _generateInviteCode();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: 7));

    final invite = PartnerInvite(
      inviterId: userId,
      inviteCode: inviteCode,
      expiresAt: expiresAt,
      createdAt: now,
    );

    final response = await _supabase
        .from('partner_invites')
        .insert(invite.toMap())
        .select()
        .single();

    return PartnerInvite.fromMap(response);
  }

  /// Get invite by code
  Future<PartnerInvite?> getInviteByCode(String code) async {
    final response = await _supabase
        .from('partner_invites')
        .select()
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();

    if (response == null) return null;
    return PartnerInvite.fromMap(response);
  }

  /// Accept a partner invite
  Future<AccountabilityPartner> acceptInvite(
    String inviteCode,
    String acceptingUserId,
  ) async {
    // Get invite
    final invite = await getInviteByCode(inviteCode);
    if (invite == null) {
      throw Exception('Invalid invite code');
    }

    if (!invite.isValid) {
      throw Exception('Invite has expired or been used');
    }

    if (invite.inviterId == acceptingUserId) {
      throw Exception('Cannot accept your own invite');
    }

    // Check if partnership already exists
    final existing = await _checkExistingPartnership(
      invite.inviterId,
      acceptingUserId,
    );
    if (existing != null) {
      throw Exception('Already partners with this user');
    }

    // Create partnership (bidirectional)
    final now = DateTime.now();

    // Partnership for inviter -> accepter
    final partner1 = AccountabilityPartner(
      userId: invite.inviterId,
      partnerId: acceptingUserId,
      status: PartnerStatus.active,
      acceptedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    // Partnership for accepter -> inviter
    final partner2 = AccountabilityPartner(
      userId: acceptingUserId,
      partnerId: invite.inviterId,
      status: PartnerStatus.active,
      acceptedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    // Insert both partnerships
    await _supabase.from('accountability_partners').insert([
      partner1.toMap(),
      partner2.toMap(),
    ]);

    // Mark invite as used
    await _supabase
        .from('partner_invites')
        .update({
          'is_used': true,
          'accepted_by_user_id': acceptingUserId,
          'accepted_at': now.toIso8601String(),
        })
        .eq('id', invite.id!);

    return partner1;
  }

  /// Get all partners for a user
  Future<List<AccountabilityPartner>> getPartners(String userId) async {
    final response = await _supabase
        .from('accountability_partners')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AccountabilityPartner.fromMap(json))
        .toList();
  }

  /// Get pending partner requests
  Future<List<AccountabilityPartner>> getPendingRequests(String userId) async {
    final response = await _supabase
        .from('accountability_partners')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AccountabilityPartner.fromMap(json))
        .toList();
  }

  /// Remove/block a partner
  Future<void> removePartner(String userId, String partnerId) async {
    // Delete both directions of partnership
    await _supabase
        .from('accountability_partners')
        .delete()
        .or('user_id.eq.$userId,partner_id.eq.$userId')
        .or('user_id.eq.$partnerId,partner_id.eq.$partnerId');
  }

  /// Check if partnership exists
  Future<AccountabilityPartner?> _checkExistingPartnership(
    String userId1,
    String userId2,
  ) async {
    final response = await _supabase
        .from('accountability_partners')
        .select()
        .eq('user_id', userId1)
        .eq('partner_id', userId2)
        .maybeSingle();

    if (response == null) return null;
    return AccountabilityPartner.fromMap(response);
  }

  /// Get all invites created by user
  Future<List<PartnerInvite>> getMyInvites(String userId) async {
    final response = await _supabase
        .from('partner_invites')
        .select()
        .eq('inviter_id', userId)
        .order('created_at', ascending: false)
        .limit(10);

    return (response as List)
        .map((json) => PartnerInvite.fromMap(json))
        .toList();
  }

  /// Delete an invite
  Future<void> deleteInvite(String inviteId) async {
    await _supabase
        .from('partner_invites')
        .delete()
        .eq('id', inviteId);
  }

  /// Generate shareable invite link
  String generateInviteLink(String inviteCode) {
    // TODO: Replace with your app's deep link scheme
    return 'https://stackhabit.app/invite/$inviteCode';
  }
}
```

### 5. Create Partner Provider

#### `lib/providers/partner_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accountability_partner.dart';
import '../services/partner_service.dart';
import 'auth_provider.dart';

// Partner Service Provider
final partnerServiceProvider = Provider<PartnerService>((ref) {
  return PartnerService();
});

// Partners List Provider
final partnersProvider = FutureProvider<List<AccountabilityPartner>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return [];

  final service = ref.read(partnerServiceProvider);
  return await service.getPartners(authState.value!.id);
});

// Pending Requests Provider
final pendingRequestsProvider = FutureProvider<List<AccountabilityPartner>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return [];

  final service = ref.read(partnerServiceProvider);
  return await service.getPendingRequests(authState.value!.id);
});
```

### 6. Create Partners Screen

#### `lib/screens/accountability/partners_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/partner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'invite_partner_sheet.dart';

class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersProvider);
    final pendingAsync = ref.watch(pendingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Accountability Partners', style: AppTextStyles.headline),
        backgroundColor: AppColors.primaryBg,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partnersProvider);
          ref.invalidate(pendingRequestsProvider);
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Header Card
            _buildHeaderCard(context),
            SizedBox(height: 24),

            // Pending Requests
            pendingAsync.when(
              data: (pending) => pending.isNotEmpty
                  ? _buildPendingSection(context, ref, pending)
                  : SizedBox.shrink(),
              loading: () => SizedBox.shrink(),
              error: (_, __) => SizedBox.shrink(),
            ),

            // Active Partners
            Text('Your Partners', style: AppTextStyles.title),
            SizedBox(height: 12),

            partnersAsync.when(
              data: (partners) => partners.isEmpty
                  ? _buildEmptyState(context, ref)
                  : Column(
                      children: partners
                          .map((partner) => _buildPartnerCard(context, ref, partner))
                          .toList(),
                    ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteSheet(context, ref),
        icon: Icon(Icons.person_add),
        label: Text('Invite Partner'),
        backgroundColor: AppColors.warmCoral,
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: AppColors.deepBlue, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share Your Journey',
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Invite up to 3 friends to be your accountability partners. See each other\'s progress and stay motivated together!',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection(
    BuildContext context,
    WidgetRef ref,
    List<AccountabilityPartner> pending,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pending Requests', style: AppTextStyles.title),
        SizedBox(height: 12),
        ...pending.map((request) => _buildPendingCard(context, ref, request)),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPendingCard(
    BuildContext context,
    WidgetRef ref,
    AccountabilityPartner request,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.warningAmber.withOpacity(0.2),
              child: Icon(Icons.person, color: AppColors.warningAmber),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.partnerName ?? 'Pending...',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Waiting for acceptance',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.hourglass_empty, color: AppColors.warningAmber),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(
    BuildContext context,
    WidgetRef ref,
    AccountabilityPartner partner,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.successGreen.withOpacity(0.2),
          child: Icon(Icons.person, color: AppColors.successGreen),
        ),
        title: Text(
          partner.partnerName ?? 'Partner',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Active since ${_formatDate(partner.acceptedAt)}',
          style: AppTextStyles.caption,
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: 18),
                  SizedBox(width: 8),
                  Text('Remove Partner'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _confirmRemovePartner(context, ref, partner);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.group_off, size: 80, color: AppColors.neutralGray),
            SizedBox(height: 16),
            Text(
              'No Partners Yet',
              style: AppTextStyles.title,
            ),
            SizedBox(height: 8),
            Text(
              'Invite friends to share your habit journey!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvitePartnerSheet(),
    );
  }

  void _confirmRemovePartner(
    BuildContext context,
    WidgetRef ref,
    AccountabilityPartner partner,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Partner?'),
        content: Text(
          'Are you sure you want to remove ${partner.partnerName ?? 'this partner'}? They will no longer see your activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(partnerServiceProvider);
                final user = ref.read(authStateProvider).value!;
                await service.removePartner(user.id, partner.partnerId);
                ref.invalidate(partnersProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Partner removed')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Remove', style: TextStyle(color: AppColors.softRed)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
```

### 7. Create Invite Sheet

#### `lib/screens/accountability/invite_partner_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/partner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class InvitePartnerSheet extends ConsumerStatefulWidget {
  const InvitePartnerSheet({super.key});

  @override
  ConsumerState<InvitePartnerSheet> createState() => _InvitePartnerSheetState();
}

class _InvitePartnerSheetState extends ConsumerState<InvitePartnerSheet> {
  String? _inviteCode;
  String? _inviteLink;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            'Invite Accountability Partner',
            style: AppTextStyles.headline.copyWith(fontSize: 20),
          ),
          SizedBox(height: 24),

          // Description
          Text(
            'Share this invite code or link with a friend. They\'ll have 7 days to accept.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: 24),

          if (_inviteCode == null)
            // Generate Button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateInvite,
              icon: Icon(Icons.add_link),
              label: Text('Generate Invite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                minimumSize: Size(double.infinity, 50),
              ),
            )
          else
            // Invite Code Display
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Invite Code',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _inviteCode!,
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 32,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Copy & Share Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: Icon(Icons.copy),
                        label: Text('Copy Code'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareInvite,
                        icon: Icon(Icons.share),
                        label: Text('Share Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmCoral,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _generateInvite() async {
    setState(() => _isGenerating = true);

    try {
      final user = ref.read(authStateProvider).value!;
      final service = ref.read(partnerServiceProvider);

      final invite = await service.createInvite(user.id);
      final link = service.generateInviteLink(invite.inviteCode);

      setState(() {
        _inviteCode = invite.inviteCode;
        _inviteLink = link;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _inviteCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite code copied!')),
    );
  }

  void _shareInvite() {
    Share.share(
      'Join me on StackHabit! Use code $_inviteCode or click: $_inviteLink',
      subject: 'Become my accountability partner!',
    );
  }
}
```

---

## Verification Checklist

- [ ] Users can generate invite codes
- [ ] Invite codes are unique and 8 characters
- [ ] Invites expire after 7 days
- [ ] Partners can accept via code
- [ ] Partnership creates bidirectional records
- [ ] Maximum 3 partners enforced
- [ ] Partner list displays correctly
- [ ] Remove partner functionality works
- [ ] Cannot accept own invite
- [ ] Cannot accept expired invite

---

## Testing Scenarios

1. **Generate Invite**: Create invite, verify code generated
2. **Share Invite**: Share via Share button, verify works
3. **Accept Invite**: Second user accepts code, verify partnership created
4. **Partner Limit**: Try to add 4th partner, verify error
5. **Expired Invite**: Wait 7+ days, try to accept, verify rejected
6. **Self Invite**: Try to accept own code, verify error
7. **Remove Partner**: Remove partner, verify deleted for both users

---

## Next Task

After completion, proceed to: [23_activity_feed.md](./23_activity_feed.md)

---

**Last Updated**: 2025-11-05
