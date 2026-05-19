import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'home_screen.dart';
import 'client_shell.dart';
import 'worker_dashboard_screen.dart';

class IdUploadScreen extends StatefulWidget {
  final bool isClient;

  const IdUploadScreen({super.key, this.isClient = false});

  @override
  State<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends State<IdUploadScreen> {
  bool isLoading = false;
  String? selectedFilePath;
  String? selectedFileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ID Verification',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Header description
            const Text(
              'Upload a government-issued ID. Stored securely – never visible to clients.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Upload area with dashed border (matching Figma)
            GestureDetector(
              onTap: selectFile,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: selectedFilePath != null
                        ? AppColors.primary
                        : const Color(0xFF999999),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selectedFilePath != null
                            ? Icons.check_circle_outline
                            : Icons.insert_drive_file_outlined,
                        size: 52,
                        color: selectedFilePath != null
                            ? AppColors.primary
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedFilePath != null
                            ? selectedFileName ?? 'File selected'
                            : 'Tap to upload',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: selectedFilePath != null
                              ? AppColors.primary
                              : Colors.black54,
                        ),
                      ),
                      if (selectedFilePath == null) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Passport, national ID, or driver\'s license',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Yellow notice card (matching Figma)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD966)),
              ),
              child: const Text(
                'Admin review: 48-hour SLA. You\'ll be notified by email once approved',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A6D00),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // Submit for review button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (isLoading || selectedFilePath == null)
                    ? null
                    : submitId,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
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
                        'Submit for review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // View submission status link
            Center(
              child: GestureDetector(
                onTap: _viewStatus,
                child: const Text(
                  'View submission status',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skip button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _skipIdUpload,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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

  Future<void> selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = result.files.first;
        setState(() {
          selectedFilePath = file.path;
          selectedFileName = file.name;
        });
      }
    } catch (e) {
      _showSnack('Error picking file. Please try again.');
    }
  }

  void submitId() async {
    if (selectedFilePath == null) {
      _showSnack('Please select a file first');
      return;
    }

    setState(() => isLoading = true);

    try {
      final api = ApiService();
      if (widget.isClient) {
        await api.uploadIdClient(selectedFilePath!);
      } else {
        await api.uploadId(selectedFilePath!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ID submitted for review!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => widget.isClient
                ? const ClientShell()
                : const WorkerDashboardScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _viewStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Submission status will be sent to your email'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _skipIdUpload() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isClient
            ? const ClientShell()
            : const WorkerDashboardScreen(),
      ),
      (route) => false,
    );
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
}

// Custom painter for dashed border (matches Figma design)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    const radius = Radius.circular(12);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}