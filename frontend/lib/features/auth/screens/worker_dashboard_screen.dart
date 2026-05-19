import 'package:flutter/material.dart';
import 'my_profile_screen.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import 'login_screen.dart';
import '../../chat/screens/chat_screen.dart'; // ← chat

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _userEmail;
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;

  bool _drawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnim;
  bool _isLoadingJobs = true;

  List<Map<String, dynamic>> _jobRequests = [];
  bool _shownPendingAlert = false;


  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerAnim = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );
    _loadUserInfo();
    _loadProfile();
    _loadJobRequests();
  }

  







  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    setState(() => _drawerOpen = true);
    _drawerController.forward();
  }

  void _closeDrawer() {
    _drawerController.reverse().then((_) {
      if (mounted) setState(() => _drawerOpen = false);
    });
  }

  Future<void> _loadUserInfo() async {
    final email = await TokenStorage.getUserEmail();
    if (!mounted) return;
    setState(() => _userEmail = email);
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = data is Map<String, dynamic> ? data : null;
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadJobRequests() async {
    try {
      final data = await ApiService().getWorkerJobRequests();
      if (!mounted) return;
      setState(() {
        _jobRequests = data.map(_jobFromApi).toList();
        _isLoadingJobs = false;
      });
      _showPendingAlertIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingJobs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    }
  }

  Map<String, dynamic> _jobFromApi(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    final budget = map['budget'];
    return {
      'id': map['id'],
      // preserve the raw Client object so the chat button can read clientId
      'Client': map['Client'],
      'clientId': map['clientId'],
      'clientName': map['clientName']?.toString() ?? 'Client',
      'title': map['title']?.toString() ?? '',
      'description': map['description']?.toString() ?? '',
      'budget': budget is num ? budget : num.tryParse('$budget') ?? 0,
      'location': map['location']?.toString() ?? '',
      'date': _formatApiDate(map['preferredDate'] ?? map['requestedAt']),
      'status': map['status']?.toString() ?? 'pending',
      'declineReason': map['declineReason']?.toString() ?? '',
    };
  }

  String _formatApiDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    const days = ['Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat', 'Sun'];
    const months = [
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
      'Dec',
    ];
    return '${days[parsed.weekday - 1]} ${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }



  String get _displayName {
    if (_userEmail == null) return 'Worker';
    final handle = _userEmail!.split('@').first;
    return handle
        .split(RegExp(r'[._-]+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String get _initials {
    final handle = _userEmail?.split('@').first ?? 'W';
    final words = handle.split(RegExp(r'[._-]+'));
    if (words.length == 1) {
      return words.first.substring(0, words.first.length.clamp(0, 2)).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  // void _handleJobAction(Map<String, dynamic> job, String action) {
  //   setState(() {
  //     final i = _jobRequests.indexWhere((j) => j['id'] == job['id']);
  //     if (i != -1) _jobRequests[i] = {..._jobRequests[i], 'status': action};
  //   });

  Future<void> _handleJobAction(Map<String, dynamic> job, String action) async {
    String? declineReason;
    if (action == 'declined') {
      declineReason = await _askDeclineReason();
      if (declineReason == null) return;
    }

    try {
      final updated = await ApiService().updateJobRequestStatus(
        job['id'],
        action,
        declineReason: declineReason,
      );
      if (!mounted) return;
      setState(() {
        final i = _jobRequests.indexWhere((j) => j['id'] == job['id']);
        if (i != -1) _jobRequests[i] = _jobFromApi(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'accepted' ? 'Job accepted!' : 'Job declined.'),
        backgroundColor: action == 'accepted' ? Colors.green : Colors.redAccent,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    }
  }

  int get _pendingCount =>
      _jobRequests.where((job) => job['status'] == 'pending').length;

  void _showPendingAlertIfNeeded() {
    if (_shownPendingAlert || _pendingCount == 0) return;
    _shownPendingAlert = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showJobAlert();
    });
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(action == 'accepted' ? 'Job accepted!' : 'Job declined.'),
    //   backgroundColor: action == 'accepted' ? Colors.green : Colors.redAccent,
    // ));
  }

  void _showJobAlert() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _BellBadge(count: _pendingCount, size: 42),
            const SizedBox(width: 12),
            const Expanded(child: Text('New job request')),
          ],
        ),
        content: Text(
          _pendingCount == 1
              ? 'You have 1 new job request waiting for your response.'
              : 'You have $_pendingCount new job requests waiting for your response.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<String?> _askDeclineReason() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _DeclineReasonDialog(),
    );
  }

  void _logout() async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await TokenStorage.clearTokens();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget get _currentPage {
    switch (_currentIndex) {
      case 0:
        return _DashboardPage(
          userEmail: _userEmail,
          profile: _profile,
          isLoading: _isLoadingProfile,
          isLoadingJobs: _isLoadingJobs,
          jobRequests: _jobRequests,
          onRefresh: () {
            setState(() => _isLoadingProfile = true);
            _loadProfile();
          },
          onJobAction: _handleJobAction,
        );
      case 1:
        return const _SearchJobsPage();
      case 2:
        return _JobsPage(jobRequests: _jobRequests);
      case 3:
        // ── NEW: Worker Messages / Inbox ──────────────────────────────────
        return _WorkerInboxPage(jobRequests: _jobRequests);
      case 4:
        return _EarningsPage(jobRequests: _jobRequests);
      case 5:
        return const MyProfileScreen();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = (_profile?['WorkerProfile'] as Map?) ?? {};
    final category = wp['category']?.toString() ?? 'Worker';
    final isVerified = wp['isVerified'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 26),
          onPressed: _openDrawer,
        ),
        title: const Text('Honar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            // icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            // onPressed: () {},
             icon: _BellBadge(count: _pendingCount),
            onPressed: _pendingCount == 0 ? null : _showJobAlert,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: AppColors.primary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work_outline), label: 'Jobs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Earnings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), label: 'Account'),
        ],
      ),
      body: Stack(
        children: [
          _currentPage,

          // Dark overlay
          if (_drawerOpen)
            FadeTransition(
              opacity: _drawerAnim,
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black54),
              ),
            ),

          // Sliding drawer
          if (_drawerOpen)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(_drawerAnim),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.82,
                height: double.infinity,
                child: _WorkerSideDrawer(
                  name: _displayName,
                  initials: _initials,
                  email: _userEmail ?? '',
                  category: category,
                  isVerified: isVerified,
                  profilePct: isVerified ? 1.0 : 0.75,
                  profilePctLabel: isVerified ? '100%' : '75%',
                  currentIndex: _currentIndex,
                  onNavigate: (index) {
                    _closeDrawer();
                    Future.delayed(const Duration(milliseconds: 200),
                        () => setState(() => _currentIndex = index));
                  },
                  onLogout: _logout,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SIDE DRAWER
// ════════════════════════════════════════════════════════════════════════════

class _WorkerSideDrawer extends StatelessWidget {
  final String name, initials, email, category;
  final bool isVerified;
  final double profilePct;
  final String profilePctLabel;
  final int currentIndex;
  final void Function(int) onNavigate;
  final VoidCallback onLogout;

  const _WorkerSideDrawer({
    required this.name,
    required this.initials,
    required this.email,
    required this.category,
    required this.isVerified,
    required this.profilePct,
    required this.profilePctLabel,
    required this.currentIndex,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1B2A),
      elevation: 16,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.5),
                      color: const Color(0xFF1A2F45),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text('Update profile',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              color: AppColors.primary, size: 10),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: profilePct,
                            backgroundColor: Colors.white12,
                            color: AppColors.primary,
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('$profilePctLabel profile complete',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Upgrade banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.workspace_premium,
                      color: Colors.amber, size: 22),
                  const SizedBox(width: 10),
                  const Text('Upgrade to Honar Pro',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ]),
              ),
            ),

            const SizedBox(height: 12),
            _Divider(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  _Tile(
                    icon: Icons.work_outline,
                    label: 'Available Jobs',
                    badge: 'New',
                    badgeColor: Colors.orange,
                    selected: currentIndex == 2,
                    onTap: () => onNavigate(2),
                  ),
                  _Tile(
                    icon: Icons.search,
                    label: 'Search Jobs',
                    selected: currentIndex == 1,
                    onTap: () => onNavigate(1),
                  ),
                  _Tile(
                    icon: Icons.bookmark_outline,
                    label: 'Saved Jobs',
                    onTap: () {},
                  ),
                  _Tile(
                    icon: Icons.bar_chart_outlined,
                    label: 'My Performance',
                    selected: currentIndex == 3,
                    onTap: () => onNavigate(3),
                  ),
                  _Tile(
                    icon: Icons.history,
                    label: 'Job History',
                    onTap: () {},
                  ),
                  _Divider(),
                  _Tile(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    selected: currentIndex == 4,
                    onTap: () => onNavigate(4),
                  ),
                  _Tile(
                    icon: Icons.verified_user_outlined,
                    label: 'ID Verification',
                    onTap: () {},
                  ),
                  _Tile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {},
                  ),
                  _Divider(),
                  _Tile(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Honar Pro',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Paid',
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    onTap: () {},
                  ),
                  _Tile(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat for Help',
                    onTap: () {},
                  ),
                  _Tile(
                    icon: Icons.info_outline,
                    label: 'How Honar Works',
                    onTap: () {},
                  ),
                ]),
              ),
            ),

            _Divider(),
            _Tile(
              icon: Icons.logout,
              label: 'Logout',
              iconColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              onTap: onLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _BellBadge extends StatelessWidget {
  final int count;
  final double size;

  const _BellBadge({required this.count, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 10,
      height: size + 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(
              Icons.notifications,
              color: const Color(0xFFF6C026),
              size: size,
            ),
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeclineReasonDialog extends StatefulWidget {
  const _DeclineReasonDialog();

  @override
  State<_DeclineReasonDialog> createState() => _DeclineReasonDialogState();
}

class _DeclineReasonDialogState extends State<_DeclineReasonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Please enter a reason');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Decline request'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        autofocus: true,
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        decoration: InputDecoration(
          hintText: 'Tell the client why you are declining',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Send reason'),
        ),
      ],
    );
  }
}


class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(
          color: Colors.white.withOpacity(0.08), height: 1, thickness: 1),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;
  final bool selected;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.trailing,
    this.selected = false,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? (selected ? AppColors.primary : Colors.white60);
    final lc = labelColor ?? (selected ? Colors.white : Colors.white70);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: ic, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: lc,
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal)),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DASHBOARD PAGE
// ════════════════════════════════════════════════════════════════════════════

class _DashboardPage extends StatelessWidget {
  final String? userEmail;
  final Map<String, dynamic>? profile;
  final bool isLoading;
    final bool isLoadingJobs;
  
  

  
  
  final List<Map<String, dynamic>> jobRequests;
  final VoidCallback onRefresh;
  final void Function(Map<String, dynamic>, String) onJobAction;

  const _DashboardPage({
    required this.userEmail,
    required this.profile,
    required this.isLoading,
     required this.isLoadingJobs,
    required this.jobRequests,
    required this.onRefresh,
    required this.onJobAction,
  });

  @override
  Widget build(BuildContext context) {
    final pending = jobRequests.where((j) => j['status'] == 'pending').toList();
    final accepted = jobRequests.where((j) => j['status'] == 'accepted').length;
    final earned = jobRequests
        .where((j) => j['status'] == 'accepted')
        .fold<int>(0, (s, j) => s + (j['budget'] as num).toInt());
    final wp = (profile?['WorkerProfile'] as Map?) ?? {};
    final category = wp['category']?.toString() ?? '';
    final city = wp['city']?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(userEmail ?? 'Worker',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  if (!isLoading && (category.isNotEmpty || city.isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.work_outline,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text('$category · $city',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                  ],
                  if (isLoading) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(
                        backgroundColor: Colors.white24, color: Colors.white),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Row(children: [
              _StatCard(
                  label: 'Pending',
                  value: '${pending.length}',
                  icon: Icons.pending_actions,
                  color: Colors.orange),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Accepted',
                  value: '$accepted',
                  icon: Icons.check_circle_outline,
                  color: Colors.green),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Earned',
                  value: 'SAR\n$earned',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary),
            ]),

            const SizedBox(height: 14),
            const _AvailabilityToggle(),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New Job Requests',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800)),
                if (pending.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${pending.length} new',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // if (pending.isEmpty)
             if (isLoadingJobs)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (pending.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('No new job requests right now.',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
              )
            else
              ...pending.map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JobRequestCard(
                      job: job,
                      onAccept: () => onJobAction(job, 'accepted'),
                      onDecline: () => onJobAction(job, 'declined'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SEARCH JOBS PAGE
// ════════════════════════════════════════════════════════════════════════════

class _SearchJobsPage extends StatefulWidget {
  const _SearchJobsPage();

  @override
  State<_SearchJobsPage> createState() => _SearchJobsPageState();
}

class _SearchJobsPageState extends State<_SearchJobsPage> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Nearby', 'High Pay', 'Urgent'];

  final List<Map<String, dynamic>> _allJobs = [
    {
      'title': 'Fix kitchen pipe leak',
      'client': 'Sarah M.',
      'location': 'Al-Malaz, Riyadh',
      'budget': 300,
      'category': 'Plumber',
      'urgent': true,
    },
    {
      'title': 'Install electrical panel',
      'client': 'Khalid R.',
      'location': 'Al-Olaya, Riyadh',
      'budget': 800,
      'category': 'Electrician',
      'urgent': false,
    },
    {
      'title': 'AC unit servicing',
      'client': 'Fatima A.',
      'location': 'Al-Nakheel, Riyadh',
      'budget': 250,
      'category': 'AC Tech',
      'urgent': false,
    },
    {
      'title': 'Bathroom renovation',
      'client': 'Omar S.',
      'location': 'Al-Wurud, Riyadh',
      'budget': 1500,
      'category': 'Carpenter',
      'urgent': true,
    },
    {
      'title': 'Water heater replacement',
      'client': 'Noura K.',
      'location': 'Al-Malaz, Riyadh',
      'budget': 450,
      'category': 'Plumber',
      'urgent': false,
    },
  ];

  List<Map<String, dynamic>> get _filtered => _allJobs.where((job) {
        final q = _query.toLowerCase();
        final mq = q.isEmpty ||
            job['title'].toString().toLowerCase().contains(q) ||
            job['category'].toString().toLowerCase().contains(q) ||
            job['location'].toString().toLowerCase().contains(q);
        final mf = switch (_activeFilter) {
          'High Pay' => (job['budget'] as int) >= 500,
          'Urgent' => job['urgent'] == true,
          _ => true,
        };
        return mq && mf;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final jobs = _filtered;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: TextField(
          controller: _ctrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search by trade, location…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    })
                : null,
            filled: true,
            fillColor: const Color(0xFFE0E0E0),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: _filters.map((f) {
            final active = _activeFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: active,
                onSelected: (_) => setState(() => _activeFilter = f),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFE8F0FE),
                labelStyle: TextStyle(
                    color: active ? Colors.white : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('${jobs.length} jobs found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: jobs.isEmpty
            ? Center(
                child: Text('No jobs found.',
                    style: TextStyle(color: Colors.grey.shade500)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _JobListingCard(job: jobs[i]),
              ),
      ),
    ]);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _JobListingCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobListingCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(job['title'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          if (job['urgent'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Urgent',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(job['client'],
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(width: 12),
          Icon(Icons.location_on_outlined,
              size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(job['location'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(job['category'],
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            Row(children: [
              Text('SAR ${job['budget']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary)),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Applied for "${job['title']}"!')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Apply',
                    style: TextStyle(fontSize: 13)),
              ),
            ]),
          ],
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// JOBS PAGE
// ════════════════════════════════════════════════════════════════════════════

class _JobsPage extends StatelessWidget {
  final List<Map<String, dynamic>> jobRequests;
  const _JobsPage({required this.jobRequests});

  @override
  Widget build(BuildContext context) {
    final groups = {
      'Pending': jobRequests.where((j) => j['status'] == 'pending').toList(),
      'Accepted': jobRequests.where((j) => j['status'] == 'accepted').toList(),
      'Declined': jobRequests.where((j) => j['status'] == 'declined').toList(),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.map((e) {
          if (e.value.isEmpty) return const SizedBox();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: e.key, count: e.value.length),
              const SizedBox(height: 10),
              ...e.value.map((j) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        _JobSummaryCard(job: j),
                        // Chat button appears below accepted jobs
                        if (j['status'] == 'accepted')
                          _JobSummaryChatButton(job: j),
                      ],
                    ),
                  )),
              const SizedBox(height: 14),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INBOX PAGE
// ════════════════════════════════════════════════════════════════════════════

class _InboxPage extends StatelessWidget {
  const _InboxPage();

  IconData _iconFor(String name) {
    switch (name) {
      case 'message': return Icons.message_outlined;
      case 'payment': return Icons.payments_outlined;
      case 'work': return Icons.work_outline;
      case 'star': return Icons.star_outline;
      default: return Icons.verified_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = [
      {'iconColor': const Color(0xFF1565C0), 'title': 'New message from Sarah M.', 'subtitle': 'Job: Fix kitchen pipe leak', 'time': '2m', 'unread': true, 'iconName': 'message'},
      {'iconColor': const Color(0xFF2E7D32), 'title': 'Payment released - SAR 250', 'subtitle': 'Bathroom tap job completed', 'time': '1h', 'unread': true, 'iconName': 'payment'},
      {'iconColor': const Color(0xFFE65100), 'title': 'New job request', 'subtitle': 'Omar A. • AC unit installation', 'time': '3h', 'unread': false, 'iconName': 'work'},
      {'iconColor': const Color(0xFFF9A825), 'title': 'New review - 5 stars', 'subtitle': '\"Professional and tidy work\"', 'time': '1d', 'unread': false, 'iconName': 'star'},
      {'iconColor': const Color(0xFF1565C0), 'title': 'ID verification approved', 'subtitle': 'Verified badge added to your profile', 'time': '2d', 'unread': false, 'iconName': 'verified'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text('Inbox', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: messages.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, i) {
              final msg = messages[i];
              final unread = msg['unread'] as bool;
              final iconColor = msg['iconColor'] as Color;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: iconColor.withOpacity(0.12),
                  child: Icon(_iconFor(msg['iconName'] as String), color: iconColor, size: 22),
                ),
                title: Text(msg['title'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: unread ? FontWeight.w700 : FontWeight.w500, color: Colors.grey.shade900)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(msg['subtitle'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(msg['time'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    if (unread) ...[
                      const SizedBox(height: 4),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle)),
                    ],
                  ],
                ),
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ACCOUNT PAGE
// ════════════════════════════════════════════════════════════════════════════

class _AccountPage extends StatefulWidget {
  final String? userEmail;
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final VoidCallback onLogout;
  final List<Map<String, dynamic>> jobRequests;
  final VoidCallback onRefresh;

  const _AccountPage({
    required this.userEmail,
    required this.profile,
    required this.isLoading,
    required this.onLogout,
    required this.jobRequests,
    required this.onRefresh,
  });

  @override
  State<_AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<_AccountPage> {

  String _initials(String? email) {
    if (email == null) return 'W';
    final parts = email.split('@').first.split(RegExp(r'[._-]+'));
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _name(String? email) {
    if (email == null) return 'Worker';
    return email.split('@').first.split(RegExp(r'[._-]+')).map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  // ── Edit Profile Bottom Sheet ─────────────────────────────────────────────
  void _showEditProfileSheet(BuildContext ctx, Map? wp) {
    final cityCtrl     = TextEditingController(text: wp?['city']?.toString() ?? '');
    final categoryCtrl = TextEditingController(text: wp?['category']?.toString() ?? '');
    final rateCtrl     = TextEditingController(text: wp?['rate']?.toString() ?? '');
    final bioCtrl      = TextEditingController(text: wp?['bio']?.toString() ?? '');
    final skillsCtrl   = TextEditingController(text: wp?['skills']?.toString() ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  const Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  const Text('Edit Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ]),
                const SizedBox(height: 16),
                _editField(categoryCtrl, 'Category', 'e.g. Plumber, Electrician', Icons.work_outline),
                const SizedBox(height: 12),
                _editField(cityCtrl, 'City', 'e.g. Riyadh, Jeddah', Icons.location_on_outlined),
                const SizedBox(height: 12),
                _editField(rateCtrl, 'Hourly Rate (SAR)', 'e.g. 150', Icons.currency_rupee, isNumber: true),
                const SizedBox(height: 12),
                _editField(skillsCtrl, 'Skills', 'Comma se alag karo: Plumber, Electrician', Icons.star_border),
                const SizedBox(height: 12),
                // Bio field (multiline)
                Text('Bio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A)),
                  decoration: InputDecoration(
                    hintText: 'Write about yourself...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        final api = ApiService();
                        await api.completeProfile({
                          'city':     cityCtrl.text.trim(),
                          'category': categoryCtrl.text.trim(),
                          'rate':     double.tryParse(rateCtrl.text.trim()) ?? 0,
                          'bio':      bioCtrl.text.trim(),
                          'skills':   skillsCtrl.text.trim(),
                        });
                        if (mounted) {
                          Navigator.pop(sheetCtx);
                          widget.onRefresh();
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setSheetState(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, String hint, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1565C0)),
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());

    final activeJobs = widget.jobRequests.where((j) => j['status'] == 'pending').length;
    final jobsDone   = widget.jobRequests.where((j) => j['status'] == 'accepted').length;
    final earned     = widget.jobRequests
        .where((j) => j['status'] == 'accepted')
        .fold<int>(0, (s, j) => s + (j['budget'] as num).toInt());
    final wp         = (widget.profile?['WorkerProfile'] as Map?) ?? {};
    final isVerified = wp['isVerified'] == true;
    final city       = wp['city']?.toString() ?? '--';
    final rateDisplay = wp['rate'] != null ? 'SAR ${wp['rate']}' : '--';

    return Container(
      color: const Color(0xFFF0F4FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(children: [

          // ── Main card ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3), width: 1.5),
            ),
            child: Column(children: [
              // Name
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Text(_name(widget.userEmail),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
              ),
              // Earnings
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'SAR ${earned.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 2),
                    Text('Earnings this month', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              // Stat boxes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  _AccStat(value: '$activeJobs', label: 'Active\njobs'),
                  const SizedBox(width: 8),
                  _AccStat(value: '$jobsDone',   label: 'Jobs\ndone'),
                  const SizedBox(width: 8),
                  _AccStat(value: rateDisplay,   label: 'Rate / hr'),
                ]),
              ),
              const SizedBox(height: 14),
              // Avatar row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1565C0).withOpacity(0.13),
                      child: Text(_initials(widget.userEmail),
                          style: const TextStyle(color: Color(0xFF1565C0), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 9, color: Colors.white),
                    ),
                  ]),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.userEmail ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text(city, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isVerified ? Colors.green : Colors.orange),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isVerified ? Icons.verified : Icons.shield_outlined,
                          size: 11, color: isVerified ? Colors.green : Colors.orange),
                      const SizedBox(width: 3),
                      Text(isVerified ? 'Verified' : 'Not Verified',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: isVerified ? Colors.green : Colors.orange)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Settings Card ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3), width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text('Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
              ),
              _AccRow(icon: Icons.edit_outlined, label: 'Edit Profile',
                  onTap: () => _showEditProfileSheet(context, wp)),
              _AccRow(icon: Icons.verified_user_outlined, label: 'ID Verification', onTap: () {}),
              _AccRow(icon: Icons.star_border,            label: 'Subscription',    onTap: () {}),
              _AccRow(icon: Icons.help_outline,           label: 'Help & Support',  onTap: () {}),
              _AccRow(icon: Icons.logout, label: 'Logout', onTap: widget.onLogout, isDestructive: true, isLast: true),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Subscription Banner ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Subscription: Pro \u2022 Active',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('until 28 May 2026', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Text('Active',
                    style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
          ),

          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}

class _AccStat extends StatelessWidget {
  final String value, label;
  const _AccStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
          const SizedBox(height: 4),
          Text(label, maxLines: 2, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.2)),
        ]),
      ),
    );
  }
}

class _AccRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLast;
  const _AccRow({required this.icon, required this.label, required this.onTap,
      this.isDestructive = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final clr  = isDestructive ? Colors.red : const Color(0xFF0D1B2A);
    final iclr = isDestructive ? Colors.red : const Color(0xFF1565C0);
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 20, color: iclr),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: clr))),
            if (!isDestructive) Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ]),
        ),
      ),
      if (!isLast) Divider(height: 1, indent: 50, color: Colors.grey.shade100),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ]),
        ),
      );
}

class _AvailabilityToggle extends StatefulWidget {
  const _AvailabilityToggle();

  @override
  State<_AvailabilityToggle> createState() => _AvailabilityToggleState();
}

class _AvailabilityToggleState extends State<_AvailabilityToggle> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: (_on ? Colors.green : Colors.grey).withOpacity(0.4)),
        ),
        child: Row(children: [
          Icon(
              _on
                  ? Icons.check_circle
                  : Icons.do_not_disturb_on_outlined,
              color: _on ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _on ? 'You are available for jobs' : 'You are not available',
              style: TextStyle(
                  color: _on
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ),
          Switch(
              value: _on,
              onChanged: (v) => setState(() => _on = v),
              activeColor: Colors.green),
        ]),
      );
}

class _JobRequestCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onAccept, onDecline;
  const _JobRequestCard(
      {required this.job, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text((job['clientName'] as String)[0],
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['clientName'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(job['date'],
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('SAR ${job['budget']}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(job['title'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(job['description'],
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.location_on_outlined,
                size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(job['location'],
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Decline',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Accept',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      );
}

class _JobSummaryCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobSummaryCard({required this.job});
  static const _colors = {
    'pending': Colors.orange,
    'accepted': Colors.green,
    'declined': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final s = job['status'] as String;
    final c = _colors[s] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(job['clientName'],
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('SAR ${job['budget']}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(s[0].toUpperCase() + s.substring(1),
                style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EARNINGS PAGE
// Shows all accepted/completed jobs and total earnings summary.
// ─────────────────────────────────────────────────────────────────────────────
class _EarningsPage extends StatelessWidget {
  final List<Map<String, dynamic>> jobRequests;
  const _EarningsPage({required this.jobRequests});

  @override
  Widget build(BuildContext context) {
    final completedJobs = jobRequests
        .where((j) => j['status'] == 'accepted' || j['status'] == 'completed')
        .toList();

    final totalEarnings = completedJobs.fold<num>(
      0,
      (sum, j) => sum + (j['budget'] as num? ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earnings',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'SAR ${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${completedJobs.length} completed job${completedJobs.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (completedJobs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 52, color: Colors.grey),
                    SizedBox(height: 14),
                    Text(
                      'No earnings yet.\nCompleted jobs will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _SectionHeader(title: 'Completed Jobs', count: completedJobs.length),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedJobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EarningRow(job: completedJobs[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  final Map<String, dynamic> job;
  const _EarningRow({required this.job});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['title'],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(job['clientName'],
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ]),
          ),
          Text('SAR ${job['budget']}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14)),
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ]);
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ─── Chat button shown below each accepted job on the worker's Jobs page ──────
class _JobSummaryChatButton extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobSummaryChatButton({required this.job});

  @override
  Widget build(BuildContext context) {
    final jobId     = job['id'] as int?;
    final clientId  = job['Client']?['id'] as int? ?? job['clientId'] as int?;
    final clientEmail = job['Client']?['email'] as String?
                     ?? job['clientName']?.toString()
                     ?? 'Client';
    if (jobId == null || clientId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          label: const Text('Chat with Client'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                jobId:          jobId,
                otherUserId:    clientId,
                otherUserEmail: clientEmail,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKER INBOX PAGE
// Shows all accepted jobs so the worker can tap to open the chat.
// This is what opens when the worker taps the "Messages" tab.
// ─────────────────────────────────────────────────────────────────────────────
class _WorkerInboxPage extends StatelessWidget {
  final List<Map<String, dynamic>> jobRequests;
  const _WorkerInboxPage({required this.jobRequests});

  @override
  Widget build(BuildContext context) {
    // Only accepted jobs have an active chat room
    final acceptedJobs = jobRequests
        .where((j) => j['status'] == 'accepted')
        .toList();

    if (acceptedJobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 52, color: Colors.grey),
            SizedBox(height: 14),
            Text(
              'No messages yet.\nAccepted jobs will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: acceptedJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final job = acceptedJobs[i];

        // Pull clientId from either the nested Client object or flat field
        final jobId      = job['id'] as int?;
        final clientId   = (job['Client'] as Map?)?['id'] as int?
                        ?? job['clientId'] as int?;
        final clientEmail = (job['Client'] as Map?)?['email'] as String?
                         ?? job['clientName']?.toString()
                         ?? 'Client';
        final title      = job['title']?.toString() ?? 'Job';

        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              clientEmail.isNotEmpty ? clientEmail[0].toUpperCase() : 'C',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(clientEmail,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            if (jobId == null || clientId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open chat – missing job info')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  jobId:          jobId,
                  otherUserId:    clientId,
                  otherUserEmail: clientEmail,
                ),
              ),
            );
          },
        );
      },
    );
  }
}