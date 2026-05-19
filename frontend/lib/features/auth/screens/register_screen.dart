import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import 'profile_screen.dart';
import 'client_profile_setup_screen.dart';
import 'subscription_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String role = "WORKER";

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  String? nameError;
  String? emailError;
  String? phoneError;
  String? passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Hon',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: 'ar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
              ),
            ],
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'I am a...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 14),

              // Role cards
              Row(
                children: [
                  Expanded(
                    child: _roleCard(
                      'Worker',
                      '🔧',
                      'Offer my services',
                      'WORKER',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _roleCard(
                      'Client',
                      '🏠',
                      'Hire a tradesperson',
                      'CLIENT',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Full name
              _fieldLabel('Full name'),
              const SizedBox(height: 8),
              _buildInput(
                controller: nameController,
                hint: 'Ahmed Al-Rashid',
                error: nameError,
                onChanged: (_) => setState(() => nameError = null),
              ),

              const SizedBox(height: 16),

              // Email
              _fieldLabel('Email'),
              const SizedBox(height: 8),
              _buildInput(
                controller: emailController,
                hint: 'ahmed@email.com',
                keyboardType: TextInputType.emailAddress,
                error: emailError,
                onChanged: (_) => setState(() => emailError = null),
              ),

              const SizedBox(height: 16),

              // Phone
              _fieldLabel('Phone'),
              const SizedBox(height: 8),
              _buildInput(
                controller: phoneController,
                hint: '+966 50 000 0000',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                error: phoneError,
                onChanged: (_) => setState(() => phoneError = null),
              ),

              const SizedBox(height: 16),

              // Password
              _fieldLabel('Password'),
              const SizedBox(height: 8),
              _buildInput(
                controller: passwordController,
                hint: '••••••••',
                isPassword: true,
                error: passwordError,
                onChanged: (_) => setState(() => passwordError = null),
              ),

              const SizedBox(height: 28),

              // Create account button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
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
                          'Create account',
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
      ),
    );
  }

  Widget _roleCard(String title, String emoji, String subtitle, String value) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: () => setState(() => role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF3FB) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
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
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? Colors.red.shade400 : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscurePassword,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
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
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    )
                  : null,
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

  void registerUser() async {
    setState(() {
      nameError = null;
      emailError = null;
      phoneError = null;
      passwordError = null;
    });

    bool hasError = false;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    // Name validation
    if (name.isEmpty) {
      setState(() => nameError = 'Please enter your full name');
      hasError = true;
    } else if (name.length < 3) {
      setState(() => nameError = 'Name must be at least 3 characters');
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      setState(() => nameError = 'Name can only contain letters and spaces');
      hasError = true;
    }

    // Email validation
    if (email.isEmpty) {
      setState(() => emailError = 'Please enter your email');
      hasError = true;
    } else if (!_isValidEmail(email)) {
      setState(() => emailError = 'Please enter a valid email address');
      hasError = true;
    }

    // Phone validation
    if (phone.isEmpty) {
      setState(() => phoneError = 'Please enter your phone number');
      hasError = true;
    } else if (!RegExp(r'^\d+$').hasMatch(phone)) {
      setState(() => phoneError = 'Phone number must contain only digits');
      hasError = true;
    } else if (phone.length != 10) {
      setState(() => phoneError = 'Phone number must be exactly 10 digits');
      hasError = true;
    }

    // Password validation
    if (password.isEmpty) {
      setState(() => passwordError = 'Please enter a password');
      hasError = true;
    } else if (password.length < 8) {
      setState(() => passwordError = 'Password must be at least 8 characters');
      hasError = true;
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(
        () =>
            passwordError = 'Password must contain at least 1 uppercase letter',
      );
      hasError = true;
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => passwordError = 'Password must contain at least 1 number');
      hasError = true;
    }

    if (hasError) return;

    setState(() => isLoading = true);

    try {
      final api = ApiService();
      await api.register(email, password, role, name: name, phone: phone);

      if (mounted) {
        if (role == 'CLIENT') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClientProfileSetupScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }

    if (mounted) setState(() => isLoading = false);
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
//  Static data tables (kept from original)
// ─────────────────────────────────────────────

const List<String> kCities = [
  'Riyadh',
  'Jeddah',
  'Dammam',
  'Makkah',
  'Madinah',
  'Khobar',
  'Taif',
  'Abha',
  'Tabuk',
  'Buraidah',
];

const List<String> kTrades = [
  'Plumber',
  'Electrician',
  'Carpenter',
  'AC Technician',
  'Painter',
  'General Worker',
];

const Map<String, Map<String, List<String>>> kTradeSkills = {
  'Plumber': {
    'Pipe Fitting': ['PVC Pipes', 'Steel Pipes', 'Copper Pipes'],
    'Leak Repair': ['Water Leaks', 'Gas Leaks'],
    'Drain Cleaning': ['Kitchen Drain', 'Bathroom Drain'],
    'Water Heater': ['Heater Install', 'Heater Repair'],
    'Toilet Repair': [],
    'Bathroom Install': [],
  },
  'Electrician': {
    'Wiring': ['New Wiring', 'Rewiring'],
    'Lighting': ['Indoor', 'Outdoor', 'LED Fitting'],
    'Fan Installation': [],
    'Circuit Breaker': ['Install', 'Repair'],
    'Outlet Repair': [],
    'Appliance Wiring': [],
  },
  'Carpenter': {
    'Furniture Assembly': [],
    'Cabinet Making': ['Kitchen Cabinets', 'Wardrobes'],
    'Door Repair': ['Interior Doors', 'Exterior Doors'],
    'Flooring': ['Wood', 'Laminate', 'Parquet'],
    'Custom Build': [],
    'Wood Finishing': [],
  },
  'AC Technician': {
    'AC Installation': ['Split AC', 'Central AC', 'Window AC'],
    'AC Repair': ['Cooling Issue', 'Noisy Unit'],
    'Gas Refill': [],
    'Filter Cleaning': [],
    'Duct Cleaning': [],
    'Thermostat': [],
  },
  'Painter': {
    'Interior Painting': [],
    'Exterior Painting': [],
    'Texture Painting': [],
    'Waterproofing': [],
    'Wall Repair': [],
  },
  'General Worker': {
    'Cleaning': ['Deep Clean', 'Regular Clean'],
    'Landscaping': [],
    'Moving Help': [],
    'Plastering': [],
    'Tiling': [],
    'Welding': [],
  },
};

const Map<String, Map<String, List<int>>> kRateSuggestions = {
  'Riyadh': {
    'Plumber': [120, 200],
    'Electrician': [100, 180],
    'Carpenter': [90, 160],
    'AC Technician': [110, 190],
    'Painter': [80, 150],
    'General Worker': [60, 120],
  },
  'Jeddah': {
    'Plumber': [100, 180],
    'Electrician': [90, 160],
    'Carpenter': [80, 150],
    'AC Technician': [100, 170],
    'Painter': [75, 140],
    'General Worker': [55, 110],
  },
  'Dammam': {
    'Plumber': [90, 160],
    'Electrician': [80, 150],
    'Carpenter': [75, 140],
    'AC Technician': [90, 160],
    'Painter': [70, 130],
    'General Worker': [55, 105],
  },
  'Makkah': {
    'Plumber': [110, 180],
    'Electrician': [90, 160],
    'Carpenter': [85, 155],
    'AC Technician': [100, 175],
    'Painter': [75, 140],
    'General Worker': [60, 115],
  },
  'Madinah': {
    'Plumber': [100, 170],
    'Electrician': [85, 155],
    'Carpenter': [80, 150],
    'AC Technician': [95, 165],
    'Painter': [72, 135],
    'General Worker': [55, 110],
  },
  'Khobar': {
    'Plumber': [95, 165],
    'Electrician': [85, 155],
    'Carpenter': [80, 145],
    'AC Technician': [90, 165],
    'Painter': [72, 135],
    'General Worker': [55, 105],
  },
  'Taif': {
    'Plumber': [85, 155],
    'Electrician': [75, 140],
    'Carpenter': [70, 130],
    'AC Technician': [85, 155],
    'Painter': [65, 120],
    'General Worker': [50, 95],
  },
  'Abha': {
    'Plumber': [80, 140],
    'Electrician': [70, 130],
    'Carpenter': [65, 120],
    'AC Technician': [80, 145],
    'Painter': [60, 115],
    'General Worker': [45, 90],
  },
  'Tabuk': {
    'Plumber': [85, 150],
    'Electrician': [75, 135],
    'Carpenter': [70, 125],
    'AC Technician': [85, 150],
    'Painter': [65, 118],
    'General Worker': [50, 95],
  },
  'Buraidah': {
    'Plumber': [90, 155],
    'Electrician': [80, 145],
    'Carpenter': [75, 135],
    'AC Technician': [88, 155],
    'Painter': [68, 125],
    'General Worker': [52, 100],
  },
};
