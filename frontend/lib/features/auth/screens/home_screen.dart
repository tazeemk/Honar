import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../models/worker_listing.dart';
import 'search_results_screen.dart';
import 'worker_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const HomeTabContent();
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  final TextEditingController _searchController = TextEditingController();
  String? userEmail;
  String? userRole;
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
      final matchesCategory = _selectedCategory == null ||
          worker.category.toLowerCase() == _selectedCategory!.toLowerCase();
      final matchesQuery = query.isEmpty ||
          worker.name.toLowerCase().contains(query) ||
          worker.category.toLowerCase().contains(query) ||
          worker.city.toLowerCase().contains(query) ||
          worker.skills.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openSearch({String initialQuery = ''}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: initialQuery,
          preloadedWorkers: _workers,
          isEmbeddedTab: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workers = _filteredWorkers;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back!",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text(userEmail ?? "User",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          GestureDetector(
            onTap: () =>
                _openSearch(initialQuery: _searchController.text.trim()),
            child: _buildSearchField(),
          ),

          const SizedBox(height: 18),
          _buildSectionTitle(context, "Categories"),
          const SizedBox(height: 10),
          _buildCategoryGrid(),
          const SizedBox(height: 18),
          _buildSectionTitle(context, "Nearby workers"),
          const SizedBox(height: 10),
          _buildWorkersList(workers),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AbsorbPointer(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search trade or location",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: const Color(0xFFE0E0E0),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ));
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
          onTap: () => setState(() {
            _selectedCategory = isSelected ? null : category.title;
          }),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon,
                    color: isSelected ? Colors.white : Colors.black87),
                const SizedBox(height: 8),
                Text(category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )),
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
              child: CircularProgressIndicator()));
    }
    if (_workerError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.redAccent.withOpacity(0.65)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
            "Could not load workers. Please restart the backend and try again.",
            style: TextStyle(color: Colors.red.shade700)),
      );
    }
    if (workers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primary.withOpacity(0.45)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("No workers found.",
            style: TextStyle(color: Colors.grey.shade700)),
      );
    }
    return ListView.separated(
      itemCount: workers.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildWorkerCard(workers[index]),
    );
  }

  Widget _buildWorkerCard(WorkerListing worker) {
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
        child: Row(
          children: [
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
                      const Icon(Icons.verified,
                          color: Colors.blue, size: 20),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text("${worker.category} - ${worker.city}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(worker.rating),
                    const SizedBox(width: 18),
                    Text(worker.jobsLabel,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(worker.rateLabel,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.title, this.icon);
  final String title;
  final IconData icon;
}