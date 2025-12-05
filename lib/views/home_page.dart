import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kazu/constants/app_colors.dart';
import 'package:kazu/controllers/pet_controller.dart';
import 'package:kazu/services/pet_services.dart';
import 'package:kazu/views/components/app_footer.dart';
import 'package:kazu/views/components/pet_card.dart';
import 'package:kazu/views/components/reminder_cart.dart';
import 'package:kazu/views/pet_register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kazu/views/profile_page.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
  Map<String, dynamic> fetcheNotificationsByMqtt = {};
  Map<String, dynamic> notifications = {};

  @override
  void initState() {
    super.initState();

    MqttHelper mqttHelper = MqttHelper();

    void _loadNotification() {
      realtimePetService.fetchNotificationFromRealtimeDB().then((data) {
        if (!mounted) return;
        setState(() {
          notifications = data ?? {};
          notificationCount = notifications['notificationCount'] ?? 0;
        });
      });
    }

    mqttHelper.connectAndListenMultipleDevicesForAlertService(deviceIds).listen(
      (alertsData) {
        if (!mounted) return;
        setState(() {
          fetcheNotificationsByMqtt = alertsData;
          _loadNotification();
          print('notifications : $notifications');
        });
      },
    );

    userName =
        RegExp(r'^([^@]+)').firstMatch(user?.email ?? 'User')?.group(1) ??
        'User';

    if (user != null) {
      print('Current user UID: ${user!.uid}');
      print('Email: ${user!.email}');
    } else {
      print('No user is currently signed in');
    }

    _loadPets();
    _loadNotification();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
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
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(pets:pets,username: userName,)),
      );
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  void _showNotificationPanel() async {
    List<Map<String, dynamic>> filterednotifications =
        await getFilteredMessages(notifications);

    await realtimePetService.UpdateNotificationCountTo0InRealtimeDB();
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
              if (filterednotifications.isNotEmpty)
                ...filterednotifications.map((notification) {
                  return _buildNotificationItem(notification['message']);
                }),
            ],
          ),
        ),
      ),
    );
  }

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
            // Top Bar
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

            // Section Header
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
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetRegister(userId: user!.uid),
                      ),
                    );
                    if (result == true) {
                      if (!mounted) return;
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

            // Pet Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: pets.map((pet) {
                  deviceIds.add(pet['deviceId']);
                  realtimePetService.updateAlertMessageToRealtimeDB(
                    pet['deviceId'],
                    fetcheNotificationsByMqtt,
                    notificationCount,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PetCard(
                      name: pet['name'],
                      deviceId: pet['deviceId'],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Reminder Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: const [ReminderCart()]),
            ),

            const SizedBox(height: 20),

            // --- Chart Analysis Section ---
            // --- Chart Analysis Section ---
            const Text(
              'Pet Activity Overview',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pets.map((pet) {
                  // Example distance walked data over 5 days
                  List<ChartData> distanceData = [
                    ChartData('Mon', pet['distanceWalkedDay1'] ?? 2),
                    ChartData('Tue', pet['distanceWalkedDay2'] ?? 3),
                    ChartData('Wed', pet['distanceWalkedDay3'] ?? 2.5),
                    ChartData('Thu', pet['distanceWalkedDay4'] ?? 4),
                    ChartData('Fri', pet['distanceWalkedDay5'] ?? 3.5),
                  ];

                  double activityLevel = pet['activityLevel'] ?? 0.7;

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        // Distance Walked Line Chart
                        SizedBox(
                          width: 250,
                          height: 200,
                          child: SfCartesianChart(
                            title: ChartTitle(text: '${pet['name']} Distance'),
                            primaryXAxis: CategoryAxis(),
                            primaryYAxis: NumericAxis(
                              minimum: 0,
                              maximum: 10,
                              interval: 2,
                              title: AxisTitle(text: 'Distance (km)'),
                            ),
                            series: <CartesianSeries<ChartData, String>>[
                              LineSeries<ChartData, String>(
                                dataSource: distanceData,
                                xValueMapper: (ChartData data, _) => data.label,
                                yValueMapper: (ChartData data, _) => data.value,
                                color: Colors.blueAccent,
                                markerSettings: const MarkerSettings(
                                  isVisible: true,
                                ),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Activity Level Donut Chart
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: SfCircularChart(
                            series: <CircularSeries<ChartData, String>>[
                              DoughnutSeries<ChartData, String>(
                                dataSource: [
                                  ChartData('Active', activityLevel * 100),
                                  ChartData(
                                    'Remaining',
                                    100 - (activityLevel * 100),
                                  ),
                                ],
                                xValueMapper: (ChartData data, _) => data.label,
                                yValueMapper: (ChartData data, _) => data.value,
                                pointColorMapper: (ChartData data, _) =>
                                    data.label == 'Active'
                                    ? Colors.greenAccent
                                    : Colors.grey[300],
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.inside,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: AppFooter(
          currentIndex: _selectedIndex,
          onTabTapped: _onTabTapped,
        ),
      ),
    );
  }
}

// --- Helper Data Class ---
class ChartData {
  final String label;
  final double value;
  ChartData(this.label, this.value);
}
