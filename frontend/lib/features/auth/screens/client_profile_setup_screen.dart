import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'subscription_screen.dart';

class ClientProfileSetupScreen extends StatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  State<ClientProfileSetupScreen> createState() =>
      _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final residenceNameController = TextEditingController();

  bool isLoading = false;

  String? cityError;
  String? addressError;
  String? residenceNameError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Client Profile',
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
            const SizedBox(height: 20),

            // ── City ───────────────────────────
            _label('City'),
            const SizedBox(height: 8),
            _buildInput(
              controller: cityController,
              hint: 'Riyadh',
              error: cityError,
              onChanged: (_) => setState(() => cityError = null),
            ),

            const SizedBox(height: 20),

            // ── Full Address ───────────────────
            _label('Full Address'),
            const SizedBox(height: 8),
            _buildInput(
              controller: addressController,
              hint: 'Street name, building number, etc.',
              maxLines: 3,
              error: addressError,
              onChanged: (_) => setState(() => addressError = null),
            ),

            const SizedBox(height: 20),

            // ── Residence/Company Name ────────
            _label('Residence or Company Name'),
            const SizedBox(height: 8),
            _buildInput(
              controller: residenceNameController,
              hint: 'Villa / Apartment / Building name',
              error: residenceNameError,
              onChanged: (_) => setState(() => residenceNameError = null),
            ),

            const SizedBox(height: 32),

            // ── Continue Button ────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _completeProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF333333),
    ),
  );

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? Colors.red.shade400 : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade600, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    // Removed - profile image not collected in client profile setup
  }

  void _completeProfile() async {
    setState(() {
      cityError = null;
      addressError = null;
      residenceNameError = null;
    });

    bool hasError = false;

    final city = cityController.text.trim();
    final address = addressController.text.trim();
    final residenceName = residenceNameController.text.trim();

    // City validation
    if (city.isEmpty) {
      setState(() => cityError = 'Please enter your city');
      hasError = true;
    }

    // Address validation
    if (address.isEmpty) {
      setState(() => addressError = 'Please enter your address');
      hasError = true;
    }

    // Residence/Company Name validation
    if (residenceName.isEmpty) {
      setState(
        () => residenceNameError = 'Please enter residence or company name',
      );
      hasError = true;
    }

    if (hasError) return;

    setState(() => isLoading = true);

    try {
      final api = ApiService();
      await api.completeClientProfile({
        'city': city,
        'address': address,
        'residenceOrCompanyName': residenceName,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(isClient: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showSnack(String msg) {
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
    cityController.dispose();
    addressController.dispose();
    residenceNameController.dispose();
    super.dispose();
  }
}
