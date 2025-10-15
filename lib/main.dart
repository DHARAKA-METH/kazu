import 'package:flutter/material.dart';
import 'package:kazu/app.dart';
// Your project imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainApp(), // use your real homepage widget
    );
  }
}
