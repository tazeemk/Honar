import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/screens/chat_screen.dart'; // ← chat

class ClientJobsScreen extends StatefulWidget {
  final VoidCallback? onChanged;

  const ClientJobsScreen({super.key, this.onChanged});

  @override
  State<ClientJobsScreen> createState() => _ClientJobsScreenState();
}

class _ClientJobsScreenState extends State<ClientJobsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];
  bool _shownResponseAlert = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService().getClientJobRequests();
      if (!mounted) return;
      setState(() {
        _jobs = data
            .whereType<Map>()
            .map((job) => Map<String, dynamic>.from(job))
            .toList();
        _isLoading = false;
      });
      widget.onChanged?.call();
      _showResponseAlertIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showResponseAlertIfNeeded() {
    if (_shownResponseAlert) return;
    final responded = _jobs.where((job) {
      final status = job['status']?.toString();
      return status == 'accepted' || status == 'declined';
    }).toList();
    if (responded.isEmpty) return;
    _shownResponseAlert = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final job = responded.first;
      final status = job['status']?.toString();
      final workerName = job['workerName']?.toString() ?? 'Worker';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                status == 'accepted' ? Icons.check_circle : Icons.cancel,
                color: status == 'accepted' ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              const Text('Request update'),
            ],
          ),
          content: Text(_ClientJobCard.statusMessage(status ?? '', workerName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Text(
            'My job requests',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _MessageCard(
              icon: Icons.error_outline,
              color: Colors.redAccent,
              title: 'Could not load requests',
              message: _error!,
            )
          else if (_jobs.isEmpty)
            const _MessageCard(
              icon: Icons.work_outline,
              color: AppColors.primary,
              title: 'No requests yet',
              message: 'Requests you send to workers will appear here.',
            )
          else
            ..._jobs.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ClientJobCard(job: job),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _ClientJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final status = job['status']?.toString() ?? 'pending';
    final workerName = job['workerName']?.toString() ?? 'Worker';
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusMessage(status, workerName),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job['title']?.toString() ?? 'Job request',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            job['description']?.toString() ?? '',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'SAR ${job['budget'] ?? '--'}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  job['location']?.toString() ?? '',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ],
          ),
          if (status == 'declined' &&
              (job['declineReason']?.toString().trim().isNotEmpty ??
                  false)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
              ),
              child: Text(
                'Reason: ${job['declineReason']}',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ],
          // ── Chat button – only shown for accepted jobs ───────────────────
          if (status == 'accepted') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 17),
                label: const Text('Chat with Worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final jobId     = job['id'] as int?;
                  final workerId  = job['Worker']?['id'] as int?
                                 ?? job['workerId'] as int?;
                  final workerEmail = job['Worker']?['email'] as String?
                                   ?? job['workerName']?.toString()
                                   ?? 'Worker';
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.pending_actions;
    }
  }

  static String statusMessage(String status, String workerName) {
    switch (status) {
      case 'accepted':
        return 'Your request has been accepted by $workerName.';
      case 'declined':
        return 'Your request was declined by $workerName.';
      default:
        return 'Waiting for $workerName to respond.';
    }
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
