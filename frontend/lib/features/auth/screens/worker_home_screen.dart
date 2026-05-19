import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'my_profile_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? userEmail;
  String? userRole;
  String? userName;
  List<WorkerListing> _workers = [];
  bool _isLoadingWorkers = true;
  String? _workerError;
  String? _selectedCategory;

  static const List<_CategoryItem> _categories = [
    _CategoryItem("Plumber", Icons.plumbing),
    _CategoryItem("Electrician", Icons.electrical_services),
    _CategoryItem("Carpenter", Icons.handyman),
    _CategoryItem("AC Tech", Icons.ac_unit),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadWorkers();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final email = await TokenStorage.getUserEmail();
    final role = await TokenStorage.getUserRole();
    if (!mounted) return;
    setState(() {
      userEmail = email;
      userRole = role;
      userName = email?.split('@').first ?? 'Worker';
    });
  }

  Future<void> _loadWorkers() async {
    try {
      final data = await ApiService().getWorkers();
      final workers = data is List
          ? data.map((item) => WorkerListing.fromJson(item)).toList()
          : <WorkerListing>[];
      if (!mounted) return;
      setState(() {
        _workers = workers;
        _isLoadingWorkers = false;
        _workerError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _workers = [];
        _isLoadingWorkers = false;
        _workerError = error.toString();
      });
    }
  }

  List<WorkerListing> get _filteredWorkers {
    final query = _searchController.text.trim().toLowerCase();
    return _workers.where((worker) {
      final matchesCategory =
          _selectedCategory == null ||
          worker.category.toLowerCase() == _selectedCategory!.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          worker.name.toLowerCase().contains(query) ||
          worker.category.toLowerCase().contains(query) ||
          worker.city.toLowerCase().contains(query) ||
          worker.skills.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature - Coming soon!")),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final workers = _filteredWorkers;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),

      // ── AppBar (same as original) ────────────────────────────────────────
      appBar: AppBar(
        title: const Text("Honar"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Naukri-style Drawer ──────────────────────────────────────────────
      drawer: Drawer(
        backgroundColor: const Color(0xFF1C2333),
        child: SafeArea(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                color: const Color(0xFF1C2333),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: 0.75,
                            strokeWidth: 3,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4FC3F7),
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (userName ?? 'W')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalize(userName ?? 'Worker'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyProfileScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Update profile',
                              style: TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.75,
                              minHeight: 6,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4FC3F7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '75% profile complete',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),

              // Upgrade Banner
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon("Honar Pro");
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.workspace_premium,
                          color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Upgrade to Honar Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerItem(
                      icon: Icons.work_outline,
                      label: 'Available Jobs',
                      isNew: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("Available Jobs");
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.search,
                      label: 'Search Jobs',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("Search Jobs");
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.bookmark_border,
                      label: 'Saved Jobs',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("Saved Jobs");
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.bar_chart,
                      label: 'My Performance',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("My Performance");
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.history,
                      label: 'Job History',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("Job History");
                      },
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    _DrawerItem(
                      icon: Icons.person_outline,
                      label: 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.verified_outlined,
                      label: 'ID Verification',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("ID Verification");
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("Settings");
                      },
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    _DrawerItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Honar Pro',
                      labelSuffix: 'Paid',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("Honar Pro");
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.help_outline,
                      label: 'Chat for Help',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("Help Chat");
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.info_outline,
                      label: 'How Honar Works',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon("How Honar Works");
                      },
                    ),
                  ],
                ),
              ),

              // Logout
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading:
                    const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(context);
                  logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      // ── Bottom Nav (same as original) ────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        backgroundColor: AppColors.primary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: "Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: "Inbox",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: "Account",
          ),
        ],
        onTap: (index) {
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProfileScreen()),
            );
          } else if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Coming soon!")),
            );
          }
        },
      ),

      // ── Body (bilkul same as original HomeScreen) ─────────────────────────
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back!",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail ?? "User",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSearchField(),
              const SizedBox(height: 18),
              _buildSectionTitle(context, "Categories"),
              const SizedBox(height: 10),
              _buildCategoryGrid(),
              const SizedBox(height: 18),
              _buildSectionTitle(context, "Nearby workers"),
              const SizedBox(height: 10),
              _buildWorkersList(workers),
              const SizedBox(height: 26),

              Text(
                "Account Status",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      "Role: ${userRole?.toUpperCase() ?? 'WORKER'}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Registration Complete! Your account is ready to use.",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: "Search trade or location",
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close, size: 18),
              ),
        filled: true,
        fillColor: const Color(0xFFE0E0E0),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      itemCount: _categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.65,
        mainAxisSpacing: 10,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategory == category.title;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _selectedCategory = isSelected ? null : category.title;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.primary : const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                const SizedBox(height: 8),
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkersList(List<WorkerListing> workers) {
    if (_isLoadingWorkers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_workerError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border.all(color: Colors.redAccent.withOpacity(0.65)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Could not load workers. Please restart the backend and try again.",
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }
    if (workers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border.all(color: AppColors.primary.withOpacity(0.45)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "No workers found.",
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }
    return ListView.separated(
      itemCount: workers.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildWorkerCard(workers[index]),
    );
  }

  Widget _buildWorkerCard(WorkerListing worker) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border.all(color: AppColors.primary.withOpacity(0.7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: worker.isVerified
                ? AppColors.primary
                : Colors.lightGreenAccent.shade400,
            child: Text(
              worker.initials,
              style:
                  const TextStyle(color: Colors.white, fontSize: 12),
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
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (worker.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          color: Colors.blue, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${worker.category} - ${worker.city}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(worker.rating),
                    const SizedBox(width: 18),
                    Text(
                      worker.jobsLabel,
                      style:
                          TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            worker.rateLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  void logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
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
}

// ── Drawer Item ──────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? labelSuffix;
  final bool isNew;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.labelSuffix,
    this.isNew = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 14)),
          if (isNew) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('New',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
          if (labelSuffix != null) ...[
            const SizedBox(width: 6),
            Text('($labelSuffix)',
                style: const TextStyle(
                    color: Color(0xFF4FC3F7), fontSize: 12)),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

// ── Models ───────────────────────────────────────────────────────────────────
class WorkerListing {
  const WorkerListing({
    required this.name,
    required this.category,
    required this.city,
    required this.skills,
    required this.rate,
    required this.currency,
    required this.isVerified,
    required this.jobCount,
    this.ratingValue,
  });

  final String name;
  final String category;
  final String city;
  final String skills;
  final double rate;
  final String currency;
  final bool isVerified;
  final int jobCount;
  final double? ratingValue;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get rateLabel => '$currency\n${rate.toStringAsFixed(0)}';
  String get jobsLabel => jobCount == 0 ? '0 jobs' : '$jobCount jobs';
  String get rating =>
      ratingValue != null ? ratingValue!.toStringAsFixed(1) : 'New';

  factory WorkerListing.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    // Backend response: User + nested WorkerProfile
    // { id, email, role, WorkerProfile: { category, city, rate, skills, isVerified } }
    final profile = json['WorkerProfile'] as Map<String, dynamic>?;

    // User model mein name nahi — email se naam banao (@ se pehle wala part)
    final email = json['email']?.toString() ?? '';
    final nameFromEmail = email.isNotEmpty
        ? email.split('@').first
        : (json['name']?.toString() ?? 'Worker');

    return WorkerListing(
      name: json['name']?.toString() ?? nameFromEmail,
      category: profile?['category']?.toString() ??
          json['category']?.toString() ??
          '',
      city: profile?['city']?.toString() ??
          json['city']?.toString() ??
          '',
      skills: profile?['skills']?.toString() ??
          json['skills']?.toString() ??
          '',
      rate: parseDouble(
          profile?['rate'] ?? json['rate'] ?? json['hourly_rate']),
      currency: json['currency']?.toString() ?? 'SAR',
      isVerified: profile?['isVerified'] == true ||
          json['is_verified'] == true ||
          json['isVerified'] == true,
      jobCount: parseInt(json['jobs_completed'] ??
          json['jobCount'] ??
          profile?['jobCount']),
      ratingValue: json['rating'] != null
          ? parseDouble(json['rating'])
          : (profile?['rating'] != null
              ? parseDouble(profile!['rating'])
              : null),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.title, this.icon);
  final String title;
  final IconData icon;
}