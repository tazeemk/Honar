import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'subscription_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bioController = TextEditingController();
  final rateController = TextEditingController();

  String? selectedTrade;
  String? selectedCity;
  String selectedRateType = 'Hourly';

  final Set<String> _selectedSkills = {};
  final Set<String> _selectedSubSkills = {};

  bool isLoading = false;

  // ── helpers ──────────────────────────────

  Map<String, List<String>> get _currentSkills =>
      selectedTrade != null ? (kTradeSkills[selectedTrade!] ?? {}) : {};

  List<int>? get _rateSuggestion {
    if (selectedCity == null || selectedTrade == null) return null;
    return kRateSuggestions[selectedCity!]?[selectedTrade!];
  }

  // ── build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Worker Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.primary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Trade category ──────────────────
            _label('Trade category'),
            const SizedBox(height: 8),
            _dropdown<String>(
              hint: 'Select your trade',
              value: selectedTrade,
              items: kTrades,
              onChanged: (v) => setState(() {
                selectedTrade = v;
                _selectedSkills.clear();
                _selectedSubSkills.clear();
              }),
            ),

            const SizedBox(height: 20),

            // ── Bio ─────────────────────────────
            _label('Bio'),
            const SizedBox(height: 8),
            _input(
              controller: bioController,
              hint: 'Tell clients about your experience...',
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // ── Rate type ───────────────────────
            _label('Rate type'),
            const SizedBox(height: 8),
            _dropdown<String>(
              hint: 'Select rate type',
              value: selectedRateType,
              items: const ['Hourly', 'Fixed'],
              onChanged: (v) => setState(() => selectedRateType = v!),
            ),

            const SizedBox(height: 20),

            // ── Rate (SAR) ──────────────────────
            _label('Rate (SAR)'),
            const SizedBox(height: 8),
            _input(
              controller: rateController,
              hint: '150',
              keyboardType: TextInputType.number,
            ),
            if (_rateSuggestion != null) ...[
              const SizedBox(height: 8),
              _rateBanner(_rateSuggestion!),
            ],

            const SizedBox(height: 20),

            // ── City ────────────────────────────
            _label('City'),
            const SizedBox(height: 8),
            _dropdown<String>(
              hint: 'Select your city',
              value: selectedCity,
              items: kCities,
              onChanged: (v) => setState(() {
                selectedCity = v;
                rateController.clear();
              }),
            ),

            const SizedBox(height: 20),

            // ── Skills ──────────────────────────
            _label('Skills'),
            const SizedBox(height: 6),
            if (selectedTrade == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Select a trade category first',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              )
            else
              _buildSkillsSection(),

            const SizedBox(height: 32),

            // ── Save ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save & continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Skills section ─────────────────────────

  Widget _buildSkillsSection() {
    // Show flat chip list matching Figma screenshot style
    final allSkillKeys = _currentSkills.keys.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        ...allSkillKeys.map((skill) {
          final subSkills = _currentSkills[skill] ?? [];
          final selected = _selectedSkills.contains(skill);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedSkills.remove(skill);
                    for (final s in subSkills) _selectedSubSkills.remove(s);
                  } else {
                    _selectedSkills.add(skill);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.grey[300]!,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        skill,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      if (subSkills.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(
                          selected
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 15,
                          color: selected ? Colors.white70 : Colors.grey[400],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (selected && subSkills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: subSkills.map((sub) {
                      final subSel = _selectedSubSkills.contains(sub);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (subSel)
                            _selectedSubSkills.remove(sub);
                          else
                            _selectedSubSkills.add(sub);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: subSel
                                ? AppColors.primary.withOpacity(0.12)
                                : const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: subSel
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            sub,
                            style: TextStyle(
                              fontSize: 12,
                              color: subSel
                                  ? AppColors.primary
                                  : Colors.grey[600],
                              fontWeight: subSel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          );
        }).toList(),
        // "+ Add skill" chip matching Figma
        GestureDetector(
          onTap: () => _showAddSkillDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  '+ Add skill',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSkillDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Select from the skills listed above'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF333333),
      ),
    );
  }

  // ── Rate suggestion banner ──────────────────

  Widget _rateBanner(List<int> r) {
    final mid = ((r[0] + r[1]) / 2).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  const TextSpan(text: 'Suggested in '),
                  TextSpan(
                    text: '$selectedCity',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ':  SAR ${r[0]}–${r[1]}/hr',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => rateController.text = mid.toString()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Use avg',
                style: TextStyle(
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

  // ── Reusable widgets ────────────────────────

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: Color(0xFF444466),
    ),
  );

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  // ── Save logic ──────────────────────────────
  // BUG FIX: was sending 'trade' key, backend expects 'category'

  void _save() async {
    if (selectedTrade == null) {
      _snack('Please select a trade category');
      return;
    }
    if (selectedCity == null) {
      _snack('Please select your city');
      return;
    }
    if (rateController.text.trim().isEmpty) {
      _snack('Please enter your rate');
      return;
    }
    if (double.tryParse(rateController.text.trim()) == null) {
      _snack('Enter a valid rate');
      return;
    }
    if (_selectedSkills.isEmpty) {
      _snack('Please select at least one skill');
      return;
    }

    setState(() => isLoading = true);

    final allSkills = [..._selectedSkills, ..._selectedSubSkills].join(', ');

    try {
      final api = ApiService();
      // FIX: use 'category' key (matches backend WorkerProfile model field)
      await api.completeProfile({
        'category':
            selectedTrade, // ✅ FIXED: was 'trade', backend expects 'category'
        'bio': bioController.text.trim(),
        'rateType': selectedRateType,
        'city': selectedCity,
        'skills': allSkills,
        'rate': double.parse(rateController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(isClient: false),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack(e.toString());
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    bioController.dispose();
    rateController.dispose();
    super.dispose();
  }
}
