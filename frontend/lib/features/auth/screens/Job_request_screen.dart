import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_service.dart';

class JobRequestScreen extends StatefulWidget {
  final Map<String, dynamic> worker;

  const JobRequestScreen({super.key, required this.worker});

  @override
  State<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> {
  final titleController =
      TextEditingController(text: 'Fix kitchen pipe leak');
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController(text: '300');
  final locationController =
      TextEditingController(text: 'Al-Malaz, Riyadh');

  DateTime selectedDate = DateTime(2026, 5, 1);
  bool isLoading = false;

  int? get _workerId {
    final raw = widget.worker['userId'] ?? widget.worker['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job request',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker mini-card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        (widget.worker['color'] as Color).withOpacity(0.15),
                    child: Text(
                      widget.worker['initials'] ?? 'MK',
                      style: TextStyle(
                        color: widget.worker['color'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.worker['fullName'] ?? widget.worker['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        widget.worker['trade'] ?? 'Plumber',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (widget.worker['isVerified'] == true)
                    const Icon(Icons.verified,
                        color: AppColors.primary, size: 16),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Job title
            _fieldLabel('Job title'),
            const SizedBox(height: 6),
            _textField(
              controller: titleController,
              hint: 'e.g. Fix kitchen pipe leak',
            ),

            const SizedBox(height: 16),

            // Description
            _fieldLabel('Description'),
            const SizedBox(height: 6),
            _textField(
              controller: descriptionController,
              hint: 'Describe the job in detail...',
              maxLines: 4,
            ),

            const SizedBox(height: 16),

            // Budget
            _fieldLabel('Proposed budget (SAR)'),
            const SizedBox(height: 6),
            _textField(
              controller: budgetController,
              hint: 'e.g. 300',
              keyboardType: TextInputType.number,
              prefixText: 'SAR ',
            ),

            const SizedBox(height: 16),

            // Preferred date
            _fieldLabel('Preferred date'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey[400]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location
            _fieldLabel('Location'),
            const SizedBox(height: 6),
            _textField(
              controller: locationController,
              hint: 'e.g. Al-Malaz, Riyadh',
              prefixIcon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 16),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Worker will contact you via messaging. Payment held in escrow until job is agreed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send job request',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF444466),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    IconData? prefixIcon,
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
            color: AppColors.primary, fontWeight: FontWeight.w600),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: Colors.grey[400])
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 13),
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

  String _formatDate(DateTime date) {
    const days = [
      'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat', 'Sun'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = days[date.weekday - 1];
    final month = months[date.month - 1];
    return '$day ${date.day} $month ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _sendRequest() async {
    if (titleController.text.trim().isEmpty) {
      _showSnack('Please enter a job title');
      return;
    }
    final budget = double.tryParse(budgetController.text.trim());
    if (budget == null || budget <= 0) {
      _showSnack('Please enter your proposed budget');
      return;
    }
    final workerId = _workerId;
    if (workerId == null) {
      _showSnack('Could not find this worker. Please go back and try again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService().createJobRequest(
        {
          'workerId': workerId,
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'budget': budget,
          'preferredDate': selectedDate.toIso8601String().split('T').first,
          'location': locationController.text.trim(),
        },
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Request Sent!'),
            ],
          ),
          content: Text(
            'Your job request has been sent to ${widget.worker['fullName'] ?? widget.worker['name']}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child:
                  const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnack(e.toString());
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
