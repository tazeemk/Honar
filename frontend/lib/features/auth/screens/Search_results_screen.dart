import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../models/worker_listing.dart';
import 'worker_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<WorkerListing>? preloadedWorkers;
  final bool isEmbeddedTab;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.preloadedWorkers,
    this.isEmbeddedTab = false,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _ctrl;
  String _activeFilter = 'All';
  bool _isLoading = true;
  String? _error;
  List<WorkerListing> _workers = [];

  final List<String> _filters = ['All', 'Verified Only', 'Under SAR 150'];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
    _ctrl.addListener(() => setState(() {}));

    if (widget.preloadedWorkers != null) {
      _workers = widget.preloadedWorkers!;
      _isLoading = false;
    } else {
      _loadWorkers();
    }
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
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _workers = [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<WorkerListing> get _filtered {
    final q = _ctrl.text.trim().toLowerCase();
    return _workers.where((w) {
      final matchQ = q.isEmpty ||
          w.name.toLowerCase().contains(q) ||
          w.category.toLowerCase().contains(q) ||
          w.city.toLowerCase().contains(q) ||
          w.skills.toLowerCase().contains(q);
      final matchF = switch (_activeFilter) {
        'Verified Only' => w.isVerified,
        'Under SAR 150' => w.rate > 0 && w.rate < 150,
        _ => true,
      };
      return matchQ && matchF;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final workers = _filtered;

    if (widget.isEmbeddedTab) {
      return SafeArea(child: _body(workers));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Search',
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: SafeArea(child: _body(workers)),
    );
  }

  Widget _body(List<WorkerListing> workers) {
    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Plumber in Riyadh',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _ctrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _ctrl.clear),
            filled: true,
            fillColor: const Color(0xFFE0E0E0),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),

      // Filter chips
      SizedBox(
        height: 38,
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
                selectedColor: const Color(0xFF008CFF),
                backgroundColor: const Color(0xFFCFE8FF),
                labelStyle: TextStyle(
                    color: active ? Colors.white : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            );
          }).toList(),
        ),
      ),

      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('${workers.length} results',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
      ),

      Expanded(child: _results(workers)),
    ]);
  }

  Widget _results(List<WorkerListing> workers) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _msgCard(
          'Could not load workers. Please restart the backend and try again.');
    }
    if (workers.isEmpty) return _msgCard('No workers found.');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      itemCount: workers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _workerCard(workers[i]),
    );
  }

  Widget _msgCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primary.withOpacity(0.45)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _workerCard(WorkerListing worker) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                WorkerDetailScreen(worker: worker.toProfileMap())),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primary.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: worker.color,
            child: Text(worker.initials,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  if (worker.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 20),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('${worker.category} · ${worker.distanceLabel} away',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  const Text('★★★★★',
                      style:
                          TextStyle(color: Colors.amber, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(worker.rating,
                      style: TextStyle(color: Colors.grey.shade600)),
                ]),
                const SizedBox(height: 2),
                Text(worker.isAvailable ? 'Available' : 'Busy',
                    style: TextStyle(
                        color: worker.isAvailable
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(worker.rateLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}