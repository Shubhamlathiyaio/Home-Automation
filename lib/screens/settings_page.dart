import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_page.dart';
import 'add_location.dart';
import 'family_collaboration.dart';
import 'all_shared_devices_page.dart';
import 'device_walkthrough_page.dart';
import '../authentication/loginpage.dart';
import 'manage_locations_page.dart';

class SettingsPage extends StatefulWidget {
  final String phoneNumber;

  const SettingsPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2D3436),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2D3436),
                          Colors.blue.shade900,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Account'),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'Manage your profile information',
                      onTap: () => _navigateTo(
                          ProfilePage(phoneNumber: widget.phoneNumber)),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.add_location_outlined,
                      title: 'Add Location',
                      subtitle: 'Add a new location to your home',
                      onTap: () =>
                          _navigateTo(AddLocation(number: widget.phoneNumber)),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.location_on_outlined,
                      title: 'Manage Locations',
                      subtitle: 'View and delete saved locations',
                      onTap: () => _navigateTo(
                          ManageLocationsPage(phoneNumber: widget.phoneNumber)),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Sharing'),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.family_restroom,
                      title: 'Family Collaboration',
                      subtitle: 'Manage family access',
                      onTap: () => _navigateTo(FamilyCollaboration(
                        phoneNumber: widget.phoneNumber,
                      )),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.devices_other,
                      title: 'Shared With Me',
                      subtitle: 'View devices shared with you',
                      onTap: () => _navigateTo(AllSharedDevicesPage(
                          phoneNumber: widget.phoneNumber)),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Help & Support'),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'How to Add Device',
                      subtitle: 'Learn how to add new devices',
                      onTap: () => _navigateTo(const DeviceWalkthroughPage()),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Read our terms and privacy policy',
                      onTap: () => _showTermsAndConditions(),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSettingsCard([
                    _buildSettingsItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      onTap: _showLogoutDialog,
                      iconColor: Colors.red,
                      textColor: Colors.red,
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 2,
        phoneNumber: widget.phoneNumber,
        areaName: '',
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF2D3436),
    Color textColor = const Color(0xFF2D3436),
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: textColor.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56);
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.red.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLogin', false);
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3436).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        'Privacy Policy',
                        'We respect your privacy and are committed to protecting your personal data. We collect only necessary information to provide our services.',
                      ),
                      _buildTermsSection(
                        'Data Collection',
                        'We collect device information, usage patterns, and location data to improve our services and provide better home automation features.',
                      ),
                      _buildTermsSection(
                        'Security',
                        'We implement industry-standard security measures to protect your data and device connections.',
                      ),
                      _buildTermsSection(
                        'Device Usage',
                        'You are responsible for maintaining the security of your devices and ensuring they are used in accordance with local regulations.',
                      ),
                      _buildTermsSection(
                        'Service Availability',
                        'While we strive for 100% uptime, we cannot guarantee uninterrupted service. Maintenance and updates may affect availability.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3436),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
