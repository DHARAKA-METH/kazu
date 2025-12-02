import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kazu/constants/app_colors.dart';
import 'package:kazu/controllers/pet_controller.dart';
import 'package:kazu/services/pet_services.dart';
import 'package:kazu/views/components/app_footer.dart';
import 'package:kazu/views/components/pet_card.dart';
import 'package:kazu/views/pet_register.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RealtimePetService realtimePetService = RealtimePetService();
  User? user = FirebaseAuth.instance.currentUser;
  late String userName;
  late int notificationCount = 2;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> pets = [];
  Timer? _timer;
  List<String> deviceIds = [];
  Map<String, dynamic> alerts = {};
  Map<String, dynamic> notifications = {};

  @override
  void initState() {
    super.initState();

    MqttHelper mqttHelper = MqttHelper();
    void _loadNotification() {
      realtimePetService.fetchNotificationFromRealtimeDB().then((data) {
        setState(() {
          notifications = data ?? {};
          notificationCount = notifications['notificationCount'] ?? 0;

        });
      });
    }

    mqttHelper.connectAndListenMultipleDevicesForAlertService(deviceIds).listen((
      alertsData,
    ) {
      setState(() {
        alerts = alertsData;
        _loadNotification();

        print(
          'notifications : $notifications',
        );

        // print(
        //   'Alerts : $alerts',
        // );
      });
    });

    // Initialize derived fields that depend on instance members
    userName =
        RegExp(r'^([^@]+)').firstMatch(user?.email ?? 'User')?.group(1) ??
        'User';

    if (user != null) {
      String uid = user!.uid; // The unique ID of the logged-in user
      String? email = user!.email; // Optional: get email
      print('Current user UID -------------------------: $uid');
      print('Email: $email');
    } else {
      print('No user is currently signed in');
    }

    _loadPets();
    _loadNotification();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _loadPets();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPets() async {
    final petData = await getPetDetails(user!.uid);
    if (!mounted) return;
    setState(() {
      pets = petData;
    });
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) {}

    setState(() {
      _selectedIndex = index;
    });

    if (index != 0) {
      // Navigate to profile page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
    // if (index == 1 ) {
    //   // Navigate to profile page
    //  Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (_) => const ProfilePage()),
    //   );
    // }
  }

  // 🔔 Show notification panel
  void _showNotificationPanel() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔔 Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildNotificationItem('Your pet left the safe zone!'),
              _buildNotificationItem('New reminder: Vet visit tomorrow.'),
              _buildNotificationItem('Feeding time in 10 minutes.'),
            ],
          ),
        ),
      ),
    );
  }

  // Notification item builder
  static Widget _buildNotificationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active,
            color: Color(0xFF42A5F5),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    RealtimePetService realtimePetService = RealtimePetService();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Bar ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar + Greeting
                Row(
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
                          'Hello',
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

                // Notification Bell
                GestureDetector(
                  onTap: _showNotificationPanel,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
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
                      // Badge
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- Section Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Pets',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final result = Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetRegister(userId: user!.uid),
                      ),
                    );
                    if (result == true) {
                      _loadPets();
                      setState(() {});
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
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
                        'assets/images/icons8-plus-48.png',
                        width: 18,
                        height: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Pet Cards List ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 8,
              ), // outer padding
              child: Row(
                children: pets.map((pet) {
                  deviceIds.add(pet['deviceId']);
                  realtimePetService.updateAlertMessageToRealtimeDB(
                    pet['deviceId'],
                    alerts,
                    notificationCount,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                    ), // space between cards
                    child: PetCard(
                      name: pet['name'],
                      deviceId: pet['deviceId'],

                      // imagePath: pet['image'], // optional
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      // Footer bar ----
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 15),
        child: AppFooter(
          currentIndex: _selectedIndex,
          onTabTapped: _onTabTapped,
        ),
      ),
    );
  }
}
