import 'package:flutter/material.dart';
import 'form_screen.dart';
import 'history_screen.dart';
import 'public_history_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [FormScreen(), HistoryScreen(), PublicHistoryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LiveBudget'), backgroundColor: Color(0xFF1A2D45)),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Hitung'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat Saya'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Publik'),
        ],
        backgroundColor: Color(0xFF1A2D45),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}