// lib/features/auth/screens/admin_dashboard_screen.dart
// Complete Admin Panel — same style as WorkerDashboardScreen & ClientShell

import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await TokenStorage.getUserEmail();
    if (!mounted) return;
    setState(() => _userEmail = email);
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
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
        return const _AdminHomePage();
      case 1:
        return const _UsersPage();
      case 2:
        return const _DisputesPage();
      case 3:
        return _AccountPage(email: _userEmail, onLogout: _logout);
      default:
        return const _AdminHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
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
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_outlined),
            label: 'Disputes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Account',
          ),
        ],
      ),
      body: _currentPage,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HOME PAGE — Dashboard summary + verification queue + disputes
// ════════════════════════════════════════════════════════════════════════════

class _AdminHomePage extends StatefulWidget {
  const _AdminHomePage();

  @override
  State<_AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<_AdminHomePage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getAdminDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerification(int id, String action) async {
    try {
      if (action == 'approve') {
        await ApiService().approveVerification(id);
      } else {
        await ApiService().rejectVerification(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve' ? '✅ Approved!' : '❌ Rejected'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
        _load(); // refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final pendingIds = _data!['pendingIds'] as int? ?? 0;
    final disputes = _data!['disputes'] as int? ?? 0;
    final queue = (_data!['verificationQueue'] as List?) ?? [];
    final activeDisputes = (_data!['activeDisputes'] as List?) ?? [];
    final stats = (_data!['stats'] as Map?) ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary Cards ──────────────────────────────────────
            Row(
              children: [
                _SummaryCard(
                  value: '$pendingIds',
                  label: 'Pending IDs',
                  color: const Color(0xFFE8F0FE),
                  textColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  value: '$disputes',
                  label: 'Disputes',
                  color: const Color(0xFFE6F4EA),
                  textColor: Colors.green.shade700,
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Verification Queue ─────────────────────────────────
            _SectionHeader(title: 'Verification queue', count: queue.length),
            const SizedBox(height: 10),

            if (queue.isEmpty)
              _EmptyState(message: 'No pending verifications')
            else
              ...queue.map(
                (item) => _VerificationCard(
                  item: item as Map<String, dynamic>,
                  onApprove: () =>
                      _handleVerification(item['id'] as int, 'approve'),
                  onReject: () =>
                      _handleVerification(item['id'] as int, 'reject'),
                ),
              ),

            const SizedBox(height: 22),

            // ── Active Disputes ────────────────────────────────────
            _SectionHeader(
              title: 'Active disputes',
              count: activeDisputes.length,
            ),
            const SizedBox(height: 10),

            if (activeDisputes.isEmpty)
              _EmptyState(message: 'No active disputes')
            else
              ...activeDisputes.map(
                (d) => _DisputeCard(dispute: d as Map<String, dynamic>),
              ),

            const SizedBox(height: 22),

            // ── Platform Stats ─────────────────────────────────────
            const _SectionHeader(title: 'Platform stats', count: -1),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  _StatRow(
                    label: 'Total workers',
                    value: '${stats['totalWorkers'] ?? 0}',
                    isLast: false,
                  ),
                  _StatRow(
                    label: 'Total clients',
                    value: '${stats['totalClients'] ?? 0}',
                    isLast: false,
                  ),
                  _StatRow(
                    label: 'Jobs this month',
                    value: '${stats['jobsThisMonth'] ?? 0}',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// USERS PAGE
// ════════════════════════════════════════════════════════════════════════════

class _UsersPage extends StatefulWidget {
  const _UsersPage();

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _allUsers = [];
  List<dynamic> _workers = [];
  List<dynamic> _clients = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getAdminUsers();
      final users = (data['users'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _workers = users.where((u) => u['role'] == 'worker').toList();
        _clients = users.where((u) => u['role'] == 'client').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: AppColors.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'All (${_allUsers.length})'),
              Tab(text: 'Workers (${_workers.length})'),
              Tab(text: 'Clients (${_clients.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _UserList(users: _allUsers, onRefresh: _load), // Pass _load
              _UserList(users: _workers, onRefresh: _load), // Pass _load
              _UserList(users: _clients, onRefresh: _load), // Pass _load
            ],
          ),
        ),
      ],
    );
  }
}

class _UserList extends StatelessWidget {
  // Changed to accept onRefresh callback
  final List<dynamic> users;
  final Future<void> Function() onRefresh; // Added onRefresh callback

  const _UserList({required this.users, required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyState(message: 'No users found');
    }
    return RefreshIndicator(
      onRefresh: onRefresh, // Use the passed onRefresh callback
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final user = users[i] as Map<String, dynamic>;
          final role = user['role'] as String? ?? '';
          final email = user['email'] as String? ?? '';
          final wp = user['WorkerProfile'] as Map?;
          final cp = user['ClientProfile'] as Map?;
          final category =
              wp?['category'] ?? cp?['residenceOrCompanyName'] ?? '';
          final city = wp?['city'] ?? cp?['city'] ?? '';
          final isVerified =
              wp?['isVerified'] == true || cp?['isVerified'] == true;

          final initials = email.isNotEmpty
              ? email.split('@').first.substring(0, 1).toUpperCase()
              : 'U';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: role == 'worker'
                      ? AppColors.primary
                      : Colors.teal,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              email.split('@').first,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...{
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          },
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty || city.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            category,
                            city,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: role == 'worker'
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: role == 'worker' ? AppColors.primary : Colors.teal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DISPUTES PAGE
// ════════════════════════════════════════════════════════════════════════════

class _DisputesPage extends StatefulWidget {
  const _DisputesPage();

  @override
  State<_DisputesPage> createState() => _DisputesPageState();
}

class _DisputesPageState extends State<_DisputesPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _disputes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getAdminDisputes();
      if (!mounted) return;
      setState(() {
        _disputes = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveDispute(int id) async {
    final ctrl = TextEditingController();
    final resolution = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter resolution notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (resolution != null && resolution.isNotEmpty) {
      try {
        await ApiService().resolveDispute(id, resolution);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Dispute resolved!'),
              backgroundColor: Colors.green,
            ),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_disputes.isEmpty) {
      return const _EmptyState(message: 'No disputes found');
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _disputes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final d = _disputes[i] as Map<String, dynamic>;
          final status = d['status'] as String? ?? 'open';
          final statusColor = switch (status) {
            'open' => Colors.orange,
            'under_review' => Colors.blue,
            'resolved' => Colors.green,
            _ => Colors.grey,
          };

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dispute #${d['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status[0].toUpperCase() +
                            status.substring(1).replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Client: ${d['clientEmail'] ?? ''} vs Worker: ${d['workerEmail'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if ((d['subject'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    d['subject'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (status == 'open' || status == 'under_review') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _resolveDispute(d['id'] as int),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Resolve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ACCOUNT PAGE
// ════════════════════════════════════════════════════════════════════════════

class _AccountPage extends StatelessWidget {
  final String? email;
  final VoidCallback onLogout;

  const _AccountPage({required this.email, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final initials = email != null && email!.isNotEmpty
        ? email!.split('@').first.substring(0, 1).toUpperCase()
        : 'A';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Admin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            email ?? '',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: const Text(
              'Admin Access',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _AccountTile(
            icon: Icons.shield_outlined,
            label: 'Admin Role',
            trailing: 'Active',
          ),
          _AccountTile(
            icon: Icons.email_outlined,
            label: 'Email',
            trailing: email ?? '',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            trailing,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color textColor;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count; // -1 to hide count

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        if (count >= 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final email = item['userEmail'] as String? ?? '';
    final profession = item['profession'] as String? ?? '';
    final docType = item['docType'] as String? ?? '';
    final createdAt = item['createdAt'] as String? ?? '';
    final nameDisplay = email.isNotEmpty ? email.split('@').first : 'Unknown';

    String timeAgo = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        profession,
                        docType,
                        timeAgo,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onApprove,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: Color(0xFF1E7E34),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onReject,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE8E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Color(0xFFC0392B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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
}

class _DisputeCard extends StatelessWidget {
  final Map<String, dynamic> dispute;
  const _DisputeCard({required this.dispute});

  @override
  Widget build(BuildContext context) {
    final clientEmail = dispute['clientEmail'] as String? ?? '';
    final workerEmail = dispute['workerEmail'] as String? ?? '';
    final clientName = clientEmail.isNotEmpty
        ? clientEmail.split('@').first
        : 'Client';
    final workerName = workerEmail.isNotEmpty
        ? workerEmail.split('@').first
        : 'Worker';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dispute #${dispute['id']}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Client: $clientName vs Worker: $workerName',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Use dynamic status color for consistency with _DisputesPage
          Builder(
            builder: (context) {
              final status = dispute['status'] as String? ?? 'open';
              final statusColor = switch (status) {
                'open' => Colors.orange,
                'under_review' => Colors.blue,
                'resolved' => Colors.green,
                _ => Colors.grey,
              };

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dispute['status']?.toString().toUpperCase() ?? 'OPEN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _StatRow({
    required this.label,
    required this.value,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.primary.withOpacity(0.1)),
              ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      ),
    );
  }
}
