import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ordersscreen.dart';
import 'tablesscreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  String waiterName = 'Garson';
  String role = '';
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      waiterName = prefs.getString('waiterName') ?? 'Garson';
      role = prefs.getString('role') ?? '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return FadeTransition(
      opacity: _animation,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: color,
          child: Container(
            height: 150,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange[50],
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _animation,
              child: Text(
                'Hoş geldin, $waiterName!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            _buildCard(
              'Masalar',
              Icons.table_bar,
              Colors.orange,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TablesScreen())),
            ),
            const SizedBox(height: 16),
            _buildCard(
              'Siparişler',
              Icons.receipt_long,
              Colors.green,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
