// ─── features/chat/screens/chat_list_screen.dart ─────────────────────────────
// The "Inbox" tab for the client.
// Shows all accepted jobs and lets the client tap to open the chat.

import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _acceptedJobs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final data = await ApiService().getClientJobRequests();
      if (!mounted) return;
      setState(() {
        // Only show accepted jobs in the inbox
        _acceptedJobs = data
            .where((j) => j is Map && j['status'] == 'accepted')
            .map((j) => Map<String, dynamic>.from(j as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_acceptedJobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text('No active chats yet.\nAccepted jobs will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _acceptedJobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final job         = _acceptedJobs[i];
          final jobId       = job['id'] as int?;
          final workerId    = job['Worker']?['id'] as int? ?? job['workerId'] as int?;
          final workerEmail = job['Worker']?['email'] as String?
                           ?? job['workerName']?.toString()
                           ?? 'Worker';
          final title       = job['title']?.toString() ?? 'Job';

          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(workerEmail, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              if (jobId == null || workerId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    jobId:          jobId,
                    otherUserId:    workerId,
                    otherUserEmail: workerEmail,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
