import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import 'client_jobs_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'my_profile_screen.dart';
import 'search_results_screen.dart';
import '../../chat/screens/chat_list_screen.dart'; // ← chat inbox
import '../../chat/services/socket_service.dart';  // ← for logout disconnect

class ClientShell extends StatefulWidget {
  final int initialIndex;
  const ClientShell({super.key, this.initialIndex = 0});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  late int _currentIndex;
  int _responseCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadResponseCount();
  }

  Future<void> _loadResponseCount() async {
    try {
      final data = await ApiService().getClientJobRequests();
      if (!mounted) return;
      setState(() {
        _responseCount = data.where((job) {
          if (job is! Map) return false;
          final status = job['status']?.toString();
          return status == 'accepted' || status == 'declined';
        }).length;
      });
    } catch (_) {}
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Logout")),
        ],
      ),
    );
    if (confirmed == true) {
      SocketService.instance.dispose(); // disconnect chat
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text("Honar"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
              icon: _BadgeIcon(
                icon: Icons.work_outline,
                count: _responseCount,
              ),
              label: "Jobs"),
          BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline), label: "Inbox"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), label: "Account"),
        ],
      ),
      // IndexedStack keeps all pages alive but only shows the current one.
      // No nested navigators = no _history.isNotEmpty crash.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeTabContent(),
          const SearchResultsScreen(query: '', isEmbeddedTab: true),
          ClientJobsScreen(onChanged: _loadResponseCount),
          const ChatListScreen(), // ← real chat inbox
          const MyProfileScreen(),
        ],
      ),
    );
  }

  Widget _comingSoon(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text("$label — Coming soon!",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(alignment: Alignment.bottomCenter, child: Icon(icon)),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
