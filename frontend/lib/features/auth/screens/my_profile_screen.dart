// import 'package:flutter/material.dart';
// import '../../../core/api/api_service.dart';
// import '../../../core/theme/app_colors.dart';

// class MyProfileScreen extends StatefulWidget {
//   const MyProfileScreen({super.key});

//   @override
//   State<MyProfileScreen> createState() => _MyProfileScreenState();
// }

// class _MyProfileScreenState extends State<MyProfileScreen> {
//   bool isLoading = true;
//   Map<String, dynamic>? profileData;
//   String? errorMsg;

//   @override
//   void initState() {
//     super.initState();
//     fetchProfile();
//   }

//   Future<void> fetchProfile() async {
//     try {
//       final api = ApiService();
//       final data = await api.getMyProfile();
//       setState(() {
//         profileData = data;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMsg = e.toString();
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1A1A2E),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
//           : errorMsg != null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                       const SizedBox(height: 12),
//                       Text(errorMsg!, style: const TextStyle(color: Colors.white)),
//                       const SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: () {
//                           setState(() { isLoading = true; errorMsg = null; });
//                           fetchProfile();
//                         },
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 )
//               : _buildProfile(),
//     );
//   }

//   Widget _buildProfile() {
//     final profile = profileData?['WorkerProfile'];
//     final email = profileData?['email'] ?? '';
//     final skills = (profile?['skills'] ?? '').toString().split(',').where((s) => s.trim().isNotEmpty).toList();

//     return RefreshIndicator(
//       onRefresh: fetchProfile,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         child: Column(
//           children: [
//             // Header Section
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF16213E),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 36,
//                         backgroundColor: AppColors.primary,
//                         child: Text(
//                           email.isNotEmpty ? email[0].toUpperCase() : 'U',
//                           style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         onPressed: () => _showEditDialog(context),
//                         icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     email,
//                     style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     profile?['category'] ?? 'Worker',
//                     style: const TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
//                       const SizedBox(width: 4),
//                       Text(
//                         profile?['city'] ?? 'Location not set',
//                         style: const TextStyle(color: Colors.white54, fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 8),

//             // Profile Performance Card
//             _buildCard(
//               title: 'Profile Performance',
//               icon: Icons.bar_chart,
//               child: Row(
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF6B5000),
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     child: const Center(
//                       child: Text('0', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text('Client actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//                       Text(
//                         profile != null ? 'Profile active' : 'Complete profile to get noticed',
//                         style: const TextStyle(color: Colors.white60, fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Basic Details Card
//             _buildCard(
//               title: 'Basic Details',
//               icon: Icons.person_outline,
//               onEdit: () => _showEditBasicDialog(context, profile),
//               child: Column(
//                 children: [
//                   _infoRow(Icons.work_outline, profile?['category'] ?? 'Not set', label: 'Category'),
//                   _infoRow(Icons.location_on_outlined, profile?['city'] ?? 'Not set', label: 'City'),
//                   _infoRow(Icons.currency_rupee, profile?['rate'] != null ? '${profile!['rate']}/hr' : 'Not set', label: 'Hourly Rate'),
//                   _infoRow(Icons.verified_user_outlined, profile?['isVerified'] == true ? 'Verified' : 'Not Verified', label: 'ID Status'),
//                 ],
//               ),
//             ),

//             // Profile Summary Card
//             _buildCard(
//               title: 'Profile Summary',
//               icon: Icons.description_outlined,
//               onEdit: () => _showEditBioDialog(context, profile),
//               child: Text(
//                 profile?['bio']?.toString().isNotEmpty == true
//                     ? profile!['bio']
//                     : 'Add a bio to tell clients about yourself and your experience.',
//                 style: TextStyle(
//                   color: profile?['bio']?.toString().isNotEmpty == true ? Colors.white : Colors.white38,
//                   fontSize: 14,
//                   height: 1.5,
//                 ),
//               ),
//             ),

//             // Skills Card
//             _buildCard(
//               title: 'Key Skills',
//               icon: Icons.star_outline,
//               onEdit: () => _showEditSkillsDialog(context, profile),
//               child: skills.isNotEmpty
//                   ? Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: skills.map((skill) => _skillChip(skill.trim())).toList(),
//                     )
//                   : const Text('Add your skills to attract more clients', style: TextStyle(color: Colors.white38, fontSize: 14)),
//             ),

//             // Subscription Status Card
//             _buildCard(
//               title: 'Subscription',
//               icon: Icons.workspace_premium_outlined,
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: profile?['subscriptionStatus'] == 'ACTIVE'
//                           ? Colors.green.withOpacity(0.2)
//                           : Colors.red.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: profile?['subscriptionStatus'] == 'ACTIVE' ? Colors.green : Colors.red,
//                       ),
//                     ),
//                     child: Text(
//                       profile?['subscriptionStatus'] ?? 'INACTIVE',
//                       style: TextStyle(
//                         color: profile?['subscriptionStatus'] == 'ACTIVE' ? Colors.green : Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Expanded(
//                     child: Text(
//                       'Subscribe to get more job opportunities',
//                       style: TextStyle(color: Colors.white60, fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCard({
//     required String title,
//     required Widget child,
//     IconData? icon,
//     VoidCallback? onEdit,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
//       padding: const EdgeInsets.all(20),
//       color: const Color(0xFF16213E),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
//               const Spacer(),
//               if (onEdit != null)
//                 GestureDetector(
//                   onTap: onEdit,
//                   child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _infoRow(IconData icon, String value, {String? label}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.white54, size: 20),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (label != null)
//                 Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
//               Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _skillChip(String skill) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.white30),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(skill, style: const TextStyle(color: Colors.white70, fontSize: 13)),
//     );
//   }

//   // ─── Edit Dialogs ───────────────────────────────────────────────────────────

//   void _showEditDialog(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Profile edit coming soon!'), duration: Duration(seconds: 2)),
//     );
//   }

//   void _showEditBasicDialog(BuildContext context, Map? profile) {
//     final cityCtrl = TextEditingController(text: profile?['city'] ?? '');
//     final categoryCtrl = TextEditingController(text: profile?['category'] ?? '');
//     final rateCtrl = TextEditingController(text: profile?['rate']?.toString() ?? '');

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF16213E),
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (_) => Padding(
//         padding: EdgeInsets.only(
//           left: 20, right: 20, top: 24,
//           bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Edit Basic Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             _dialogField(cityCtrl, 'City'),
//             const SizedBox(height: 12),
//             _dialogField(categoryCtrl, 'Category (e.g. Plumber, Electrician)'),
//             const SizedBox(height: 12),
//             _dialogField(rateCtrl, 'Hourly Rate', isNumber: true),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   try {
//                     final api = ApiService();
//                     await api.completeProfile({
//                       'city': cityCtrl.text.trim(),
//                       'category': categoryCtrl.text.trim(),
//                       'rate': double.tryParse(rateCtrl.text.trim()) ?? 0,
//                     });
//                     fetchProfile();
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('✅ Profile updated!'), backgroundColor: Colors.green),
//                       );
//                     }
//                   } catch (e) {
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
//                     }
//                   }
//                 },
//                 child: const Text('Save', style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showEditBioDialog(BuildContext context, Map? profile) {
//     final bioCtrl = TextEditingController(text: profile?['bio'] ?? '');
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF16213E),
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (_) => Padding(
//         padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Edit Profile Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             TextField(
//               controller: bioCtrl,
//               maxLines: 5,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: 'Write about yourself...',
//                 hintStyle: const TextStyle(color: Colors.white38),
//                 filled: true,
//                 fillColor: const Color(0xFF1A1A2E),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   try {
//                     final api = ApiService();
//                     await api.completeProfile({'bio': bioCtrl.text.trim()});
//                     fetchProfile();
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('✅ Bio updated!'), backgroundColor: Colors.green),
//                       );
//                     }
//                   } catch (e) {
//                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
//                   }
//                 },
//                 child: const Text('Save', style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showEditSkillsDialog(BuildContext context, Map? profile) {
//     final skillsCtrl = TextEditingController(text: profile?['skills'] ?? '');
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF16213E),
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (_) => Padding(
//         padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Edit Skills', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             const Text('Comma se alag karo, e.g. Plumber, Electrician, Cleaner', style: TextStyle(color: Colors.white38, fontSize: 12)),
//             const SizedBox(height: 16),
//             _dialogField(skillsCtrl, 'Skills (comma separated)'),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   try {
//                     final api = ApiService();
//                     await api.completeProfile({'skills': skillsCtrl.text.trim()});
//                     fetchProfile();
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('✅ Skills updated!'), backgroundColor: Colors.green),
//                       );
//                     }
//                   } catch (e) {
//                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
//                   }
//                 },
//                 child: const Text('Save', style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _dialogField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
//     return TextField(
//       controller: ctrl,
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: const TextStyle(color: Colors.white38),
//         filled: true,
//         fillColor: const Color(0xFF1A1A2E),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';
import 'id_upload_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic>? profileData;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final api = ApiService();
      final data = await api.getMyProfile();
      setState(() {
        profileData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TokenStorage.clearTokens();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(errorMsg!, style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { isLoading = true; errorMsg = null; });
                          fetchProfile();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildAccount(),
    );
  }

  Widget _buildAccount() {
    final wp = (profileData?['WorkerProfile'] as Map?) ?? {};
    final email = profileData?['email']?.toString() ?? '';
    final name = profileData?['name']?.toString() ?? '';
    final displayName = name.isNotEmpty ? name : email.split('@').first;
    final initials = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase();
    final city = wp['city']?.toString() ?? '';
    final isVerified = wp['isVerified'] == true;
    final subStatus = wp['subscriptionStatus']?.toString() ?? 'INACTIVE';
    final isSubActive = subStatus == 'ACTIVE';

    // Earnings stats from profile (0 by default if not available)
    final activeJobs = (profileData?['activeJobs'] ?? 0) as int? ?? 0;
    final jobsDone = (profileData?['jobsDone'] ?? 0) as int? ?? 0;
    final rate = wp['rate'];
    final rateDisplay = rate != null ? 'SAR ${rate.toString()}' : 'SAR 0';

    return RefreshIndicator(
      onRefresh: fetchProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ── Top Stats Card ───────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  // Earnings this month
                  const Text('SAR 0', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Text('Earnings this month', style: TextStyle(color: Colors.black45, fontSize: 13)),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _statBox('$activeJobs', 'Active\njobs'),
                      const SizedBox(width: 12),
                      _statBox('$jobsDone', 'Jobs\ndone'),
                      const SizedBox(width: 12),
                      _statBox(rateDisplay, 'Rate / hr', highlight: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Profile info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                            if (city.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 13, color: Colors.black45),
                                  const SizedBox(width: 2),
                                  Text(city, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: isVerified ? Colors.green : Colors.orange),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified ? Icons.verified_outlined : Icons.hourglass_empty,
                              size: 13,
                              color: isVerified ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? 'Verified' : 'Not Verified',
                              style: TextStyle(
                                fontSize: 12,
                                color: isVerified ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Settings Card ────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  ),
                  _settingsTile(
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.primary,
                    label: 'Edit Profile',
                    onTap: () => _showEditBasicDialog(context, wp),
                  ),
                  _divider(),
                  _settingsTile(
                    icon: Icons.verified_user_outlined,
                    iconColor: AppColors.primary,
                    label: 'ID Verification',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdUploadScreen())),
                  ),
                  _divider(),
                  _settingsTile(
                    icon: Icons.star_border_outlined,
                    iconColor: AppColors.primary,
                    label: 'Subscription',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                  ),
                  _divider(),
                  _settingsTile(
                    icon: Icons.help_outline,
                    iconColor: AppColors.primary,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _divider(),
                  _settingsTile(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    label: 'Logout',
                    labelColor: Colors.red,
                    onTap: _logout,
                    showArrow: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Subscription Banner ──────────────────────────────────────
            if (isSubActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subscription: Pro • Active',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('Subscription is active',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Active',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _statBox(String value, String label, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: highlight ? 15 : 20,
                    color: highlight ? AppColors.primary : Colors.black87)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    bool showArrow = true,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(label,
          style: TextStyle(fontSize: 15, color: labelColor ?? Colors.black87, fontWeight: FontWeight.w500)),
      trailing: showArrow ? const Icon(Icons.chevron_right, color: Colors.black26) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFEEEEEE));

  // ── Edit Dialog ──────────────────────────────────────────────────────────────

  void _showEditBasicDialog(BuildContext context, Map wp) {
    final cityCtrl = TextEditingController(text: wp['city'] ?? '');
    final categoryCtrl = TextEditingController(text: wp['category'] ?? '');
    final rateCtrl = TextEditingController(text: wp['rate']?.toString() ?? '');
    final bioCtrl = TextEditingController(text: wp['bio'] ?? '');
    final skillsCtrl = TextEditingController(text: wp['skills'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _dialogField(cityCtrl, 'City'),
              const SizedBox(height: 12),
              _dialogField(categoryCtrl, 'Category (e.g. Plumber, Electrician)'),
              const SizedBox(height: 12),
              _dialogField(rateCtrl, 'Hourly Rate', isNumber: true),
              const SizedBox(height: 12),
              _dialogField(bioCtrl, 'Bio'),
              const SizedBox(height: 12),
              _dialogField(skillsCtrl, 'Skills (comma separated)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await ApiService().completeProfile({
                        'city': cityCtrl.text.trim(),
                        'category': categoryCtrl.text.trim(),
                        'rate': double.tryParse(rateCtrl.text.trim()) ?? 0,
                        'bio': bioCtrl.text.trim(),
                        'skills': skillsCtrl.text.trim(),
                      });
                      fetchProfile();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Profile updated!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}