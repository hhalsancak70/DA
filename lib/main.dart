import 'package:digiadi/screens/loginscreen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DigiAdi',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: const LoginScreen(),
    );
  }
}
