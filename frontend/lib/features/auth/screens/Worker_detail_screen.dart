import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_service.dart';
import 'Job_request_screen.dart';

class WorkerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> worker;

  const WorkerDetailScreen({super.key, required this.worker});

  static void navigateIfWorker(
    BuildContext context,
    Map<String, dynamic> worker,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker)),
    );
  }

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final _api = ApiService();

  bool _isFavorite = false;
  bool _favoriteLoading = true;
  bool _toggling = false;

  Color get _workerColor => widget.worker['color'] is Color
      ? widget.worker['color'] as Color
      : AppColors.primary;

  double get _rating {
    final v = widget.worker['rating'];
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  int? get _workerProfileId {
    // Look for common ID keys: workerProfileId, id, or userId
    final raw = widget.worker['workerProfileId'] ?? 
                widget.worker['id'] ?? 
                widget.worker['userId'];
    if (raw is int) return raw;
    if (raw != null) return int.tryParse(raw.toString());
    return null;
  }

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final id = _workerProfileId;
    if (id == null) {
      if (mounted) setState(() => _favoriteLoading = false);
      return;
    }
    try {
      final isFav = await _api.checkFavorite(id);
      if (mounted)
        setState(() {
          _isFavorite = isFav;
          _favoriteLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final id = _workerProfileId;
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Worker ID not found')));
      return;
    }

    setState(() => _toggling = true);
    try {
      final result = await _api.toggleFavorite(id);
      final nowFav = result['isFavorite'] as bool? ?? !_isFavorite;
      final msg =
          result['message'] as String? ??
          (nowFav ? 'Saved to favorites' : 'Removed from favorites');

      if (mounted) {
        setState(() {
          _isFavorite = nowFav;
          _toggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  nowFav ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(msg),
              ],
            ),
            backgroundColor: nowFav ? Colors.red[400] : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _toggling = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!_favoriteLoading)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: _toggling ? null : _toggleFavorite,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _workerColor.withOpacity(0.15),
                    child: Text(
                      worker['initials'] ?? 'WK',
                      style: TextStyle(
                        color: _workerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          worker['fullName'] ?? worker['name'] ?? 'Worker',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      if (worker['isVerified'] == true) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${worker['trade'] ?? worker['category'] ?? ''} · ${worker['city'] ?? ''}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (worker['isVerified'] == true)
                        _badge('Verified', Colors.green),
                      if (worker['isAvailable'] == true)
                        _badge('Available', Colors.green),
                      if (_rating >= 4.5)
                        _badge(
                          'Top Rated',
                          const Color(0xFFFFC107),
                          textColor: Colors.black87,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _statItem(
                          _rating > 0 ? _rating.toStringAsFixed(1) : 'New',
                          'Rating',
                          Icons.star,
                          const Color(0xFFFFC107),
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _statItem(
                          '${worker['jobsDone'] ?? 0}',
                          'Jobs done',
                          Icons.work_outline,
                          AppColors.primary,
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _statItem(
                          '${worker['experience'] ?? 0}yr',
                          'Experience',
                          Icons.timeline,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // About
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    worker['bio'] ?? 'No bio available.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Reviews
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${worker['reviews'] ?? 0} reviews',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _reviewCard(
                    name: worker['reviewerName'] ?? 'Client',
                    text: worker['review'] ?? 'Good and professional service.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobRequestScreen(worker: worker),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Send job request',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // SAVE TO FAVORITES BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _favoriteLoading
                        ? OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _toggling ? null : _toggleFavorite,
                            icon: _toggling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Icon(
                                    _isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isFavorite
                                        ? Colors.red
                                        : AppColors.primary,
                                    size: 18,
                                  ),
                            label: Text(
                              _isFavorite
                                  ? 'Saved to favorites'
                                  : 'Save to favorites',
                              style: TextStyle(
                                color: _isFavorite
                                    ? Colors.red
                                    : AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _isFavorite
                                    ? Colors.red
                                    : AppColors.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color == const Color(0xFFFFC107) ? Colors.black87 : color,
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _verticalDivider() =>
      Container(height: 48, width: 1, color: Colors.grey[200]);

  Widget _sectionCard({required Widget child}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: child,
    );
  }

  Widget _reviewCard({required String name, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (_) => const Icon(
                    Icons.star,
                    size: 11,
                    color: Color(0xFFFFC107),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
