import 'package:flutter/material.dart';
import 'package:kazu/views/components/app_footer.dart';
import 'package:kazu/views/home_page.dart';

class ProfilePage extends StatefulWidget {
  late List<Map<String, dynamic>> pets;
  final String username;

  ProfilePage({super.key, required this.pets, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 1;

  void _onTabTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      return;
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.username}\'s Profile')),
      body: ListView.builder(
        itemCount: widget.pets.length,
        itemBuilder: (context, index) {
          final pet = widget.pets[index];
          return ListTile(
            leading: Icon(Icons.pets),
            title: Text(pet['name'] ?? 'Unknown Pet'),
            subtitle: Text('Device ID: ${pet['deviceId'] ?? 'N/A'}'),
          );
        },
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
