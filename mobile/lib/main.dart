import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Panggil loadUser() langsung saat provider dibuat
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
      ],
      child: MaterialApp(
        title: 'LiveBudget',
        theme: ThemeData.dark().copyWith(
          primaryColor: Color(0xFF1A2D45),
          scaffoldBackgroundColor: Color(0xFF0F1B2D),
          appBarTheme: AppBarTheme(backgroundColor: Color(0xFF1A2D45)),
        ),
        home: Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            // Tampilkan loading selama proses autentikasi
            if (auth.isLoading) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Jika sudah login, tampilkan halaman utama
            if (auth.user != null) {
              return HomeScreen();
            }
            // Jika belum login, tampilkan halaman login
            return LoginScreen();
          },
        ),
        routes: {
          '/login': (ctx) => LoginScreen(),
          '/register': (ctx) => RegisterScreen(),
        },
      ),
    );
  }
}