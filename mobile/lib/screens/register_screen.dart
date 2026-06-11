import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate() && _passCtrl.text == _confirmCtrl.text) {
      final success = await context.read<AuthProvider>().register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
      if (success) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrasi gagal'), backgroundColor: Colors.red));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password tidak cocok'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar'), backgroundColor: Color(0xFF1A2D45)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Nama'), validator: (v) => v!.isEmpty ? 'Isi nama' : null),
              SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email'), validator: (v) => v!.isEmpty ? 'Isi email' : null),
              SizedBox(height: 12),
              TextFormField(controller: _passCtrl, decoration: InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v!.isEmpty ? 'Isi password' : null),
              SizedBox(height: 12),
              TextFormField(controller: _confirmCtrl, decoration: InputDecoration(labelText: 'Konfirmasi Password'), obscureText: true, validator: (v) => v!.isEmpty ? 'Konfirmasi password' : null),
              SizedBox(height: 24),
              context.watch<AuthProvider>().isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(onPressed: _register, child: Text('Daftar'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48))),
            ],
          ),
        ),
      ),
    );
  }
}