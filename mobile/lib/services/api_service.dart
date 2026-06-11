import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/calculation.dart';

class ApiService {
  // Ganti dengan IP komputer Anda (pastikan perangkat terhubung ke jaringan yang sama)
  static const String baseUrl = 'http://192.168.0.106:8000/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return User.fromJson(data['user']);
    }
    return null;
  }

  Future<User?> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'password_confirmation': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return User.fromJson(data['user']);
    }
    return null;
  }

  Future<User?> getCurrentUser() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/user'), headers: headers);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<Map<String, dynamic>> calculate(Map<String, dynamic> data) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/calculate'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal menghitung: ${response.body}');
    }
  }

  Future<List<Calculation>> getHistory(int userId) async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/history/$userId'), headers: headers);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Calculation.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil riwayat');
    }
  }

  Future<Map<String, dynamic>> getPublicHistory({int page = 1, int perPage = 15, String sortBy = 'created_at', String sortDirection = 'desc'}) async {
    final headers = await _headers();
    final url = Uri.parse('$baseUrl/public-history?page=$page&per_page=$perPage&sort_by=$sortBy&sort_direction=$sortDirection');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat data publik');
    }
  }

  Future<Calculation> updateCalculation(int id, Map<String, dynamic> data) async {
    final headers = await _headers();
    final response = await http.put(Uri.parse('$baseUrl/update/$id'), headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {
      return Calculation.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Gagal update');
    }
  }

  Future<void> deleteCalculation(int id) async {
    final headers = await _headers();
    final response = await http.delete(Uri.parse('$baseUrl/delete/$id'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Gagal hapus');
    }
  }
}