import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<AuthProvider>().login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (success) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login gagal'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LiveBudget'), backgroundColor: Color(0xFF1A2D45)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email'), validator: (v) => v!.isEmpty ? 'Isi email' : null),
              SizedBox(height: 12),
              TextFormField(controller: _passCtrl, decoration: InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v!.isEmpty ? 'Isi password' : null),
              SizedBox(height: 24),
              context.watch<AuthProvider>().isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(onPressed: _login, child: Text('Masuk'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48))),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())), child: Text('Belum punya akun? Daftar')),
            ],
          ),
        ),
      ),
    );
  }
}