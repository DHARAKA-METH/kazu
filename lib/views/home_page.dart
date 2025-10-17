import 'package:flutter/material.dart';
import 'package:kazu/constants/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // User name to display
  final String userName = "Dharaka";

  // Number of unread notifications
  final String notificationCount = "4";

  // 🔔 Function to show notification panel on tap
  void _showNotificationPanel() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows tapping outside to close
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel title
                const Text(
                  '🔔 Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(), // Divider line
                const SizedBox(height: 8),
                // List of notifications
                _buildNotificationItem('Your pet left the safe zone!'),
                _buildNotificationItem('New reminder: Vet visit tomorrow.'),
                _buildNotificationItem('Feeding time in 10 minutes.'),
              ],
            ),
          ),
        );
      },
    );
  }

  // 📨 Builds a single notification item with icon and text
  static Widget _buildNotificationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active,
            color: Color(0xFF42A5F5), // Blue icon
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF1E293B)), // Dark text
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Dark background
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 45.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between avatar and bell
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // 👤 Left side: Avatar + Greeting
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/avators.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hello",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 🔔 Right side: Notification bell with badge
            GestureDetector(
              onTap: _showNotificationPanel, // Opens notification panel
              child: Stack(
                clipBehavior: Clip.none, // Allows badge to overflow
                children: [
                  // Circular bell button
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white, // White background
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/notification-bell-64.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),

                  // 🔴 Red badge showing unread count
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red, // Badge color
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5), // White border
                      ),
                      child: Text(
                        notificationCount, // Badge number
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
