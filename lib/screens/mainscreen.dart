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
      String title, IconData icon, Color color, Color shadowColor, VoidCallback onTap) {
    return FadeTransition(
      opacity: _animation,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon, 
                        size: 42, 
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeTransition(
                      opacity: _animation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DigiAdi',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hoş geldin, $waiterName!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.deepOrange.shade400,
                      radius: 24,
                      child: Text(
                        waiterName.isNotEmpty ? waiterName[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hızlı Erişim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                          children: [
                            _buildCard(
                              'Masalar',
                              Icons.table_bar,
                              Colors.deepOrange,
                              Colors.deepOrange,
                              () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const TablesScreen())),
                            ),
                            _buildCard(
                              'Siparişler',
                              Icons.receipt_long,
                              Colors.green.shade600,
                              Colors.green,
                              () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const OrdersScreen())),
                            ),
                            // Diğer hızlı erişim kartları
                            _buildCard(
                              'Günlük Özet',
                              Icons.analytics,
                              Colors.indigo.shade600,
                              Colors.indigo,
                              () => _showFeatureUnderDevelopment(context),
                            ),
                            _buildCard(
                              'Ayarlar',
                              Icons.settings,
                              Colors.blueGrey.shade600,
                              Colors.blueGrey,
                              () => _showFeatureUnderDevelopment(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showFeatureUnderDevelopment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu özellik henüz geliştirme aşamasındadır.'),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        margin: EdgeInsets.all(10),
      ),
    );
  }
}
