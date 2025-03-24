import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:async';
class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  final String _baseUrl = 'https://proyect-currier.onrender.com'; // Update with your backend URL
  static const String CLIENT_SECRET_KEY = '2454619e5c46941ea1be0cebb2df67577070f3861a7f5df8dd8ca0c81deaf4fe';
  static const String ADMIN_SECRET_KEY = '22765924bc2a9a1485a2d9473399d9b6b3578e1f253baaf2ba81199982a57cf535dfecf487946efd51f85c613f6ac78882fe9b2246f4552058805da328682dbd'; 
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'ADMIN';
  DateTime? _lastValidation;
  static const validationInterval = Duration(minutes: 5);

  final _storage = const FlutterSecureStorage();
   String? _sessionId;
  String? _token;
static const sessionTimeout = Duration(hours: 24);
 DateTime? _lastActivity;

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'model': androidInfo.model,
          'platform': 'android'
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor,
          'model': iosInfo.model,
          'platform': 'ios'
        };
      } else {
        WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        return {
          'deviceId': webInfo.vendor! + webInfo.userAgent!,
          'platform': 'web'
        };
      }
    } catch (e) {
      return {'deviceId': 'unknown', 'platform': 'unknown'};
    }
  }


  Future<bool> login(String email, String password) async {
  try {
    _isLoading = true;
    notifyListeners();

    final response = await http.post(
      Uri.parse('$_baseUrl/Login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    print('Login response: ${response.body}');
    final data = json.decode(response.body);
    
    if (response.statusCode == 200 && data['token'] != null) {
      // Store token without Bearer prefix
      final token = data['token'];
      await _storage.write(key: 'token', value: token);
       await _storage.write(key: 'userId', value: data['userId']);
      print('Token stored: $token');

      // Extract user ID from JWT token
      final parts = token.split('.');
      if (parts.length > 1) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
        );
        final userId = payload['id'];
        
        if (userId != null) {
          await _storage.write(key: 'id', value: userId);
          print('User ID stored: $userId');
        }
      }

      // Store last activity
      _lastActivity = DateTime.now();
      await _storage.write(
        key: 'lastActivity',
        value: _lastActivity!.toIso8601String()
      );

      // Set session duration (4 hours)
      await _storage.write(
        key: 'sessionDuration',
        value: (4 * 60 * 60 * 1000).toString()
      );

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    print('Login error: $e');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

// Add session check method
Future<bool> checkSession() async {
  final lastActivityStr = await _storage.read(key: 'lastActivity');
  final token = await _storage.read(key: 'token');
  
  if (lastActivityStr == null || token == null) {
    return false;
  }

  final lastActivity = DateTime.parse(lastActivityStr);
  final now = DateTime.now();
  final difference = now.difference(lastActivity).inHours;

  // Session expires after 4 hours
  if (difference >= 4) {
    await logout();
    return false;
  }

  // Update last activity
  _lastActivity = now;
  await _storage.write(
    key: 'lastActivity',
    value: _lastActivity!.toIso8601String()
  );
  
  return true;
}
  Future<bool> checkAuth() async {
  try {
    // Check validation interval
    if (_lastValidation != null && 
        DateTime.now().difference(_lastValidation!) < validationInterval) {
      return _currentUser != null;
    }

    _token = await _storage.read(key: 'token');
    final lastActivityStr = await _storage.read(key: 'lastActivity');
    
    if (_token == null || lastActivityStr == null) {
      notifyListeners();
      return false;
    }

    // Add Bearer prefix if not present
    final authToken = _token!.startsWith('Bearer ') ? _token! : 'Bearer $_token';

    _lastValidation = DateTime.now();
    final response = await http.get(
      Uri.parse('$_baseUrl/validate'),
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
      },
    );

    print('Validate response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _currentUser = User(
        id: data['id'] ?? '',
        name: data['nombre'] ?? '',
        apellido: data['apellido'] ?? '',
        email: data['email'] ?? '',
        direccion: data['direccion'] ?? '',
        telefono: data['telefono'] ?? '',
        ciudad: data['ciudad'] ?? '',
        pais: data['pais'] ?? '',
        role: data['rol'] ?? 'CLIENTE',
      );
      
      _lastActivity = DateTime.now();
      await _storage.write(
        key: 'lastActivity',
        value: _lastActivity!.toIso8601String()
      );

      notifyListeners();
      return true;
    }

    await logout();
    return false;
  } catch (e) {
    print('Auth check error: $e');
    await logout();
    return false;
  }
}
 Future<Map<String, dynamic>> register({
  required String nombre,
  required String apellido,
  required String email,
  required String password,
  required String direccion,
  required String telefono,
  required String ciudad,
  required String pais,
}) async {
  try {
    _isLoading = true;
    notifyListeners();

    print('Sending registration request to: $_baseUrl/register');
    print('Request body: ${json.encode({
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'contraseña': password,
      'Direccion': direccion,
      'Telefono': telefono,
      'ciudad': ciudad,
      'Pais': pais,
    })}');

    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'contraseña': password,
        'Direccion': direccion,
        'Telefono': telefono,
        'ciudad': ciudad,
        'Pais': pais,
      }),
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    final data = json.decode(response.body);
    _isLoading = false;
      notifyListeners();
    if (response.statusCode == 201) {
      print('Registration successful');
      return {
        'success': true,
        'message': data['message'],
        'userId': data['UserId'],
      };
    }

    _isLoading = false;
    notifyListeners();
    
    print('Registration failed with message: ${data['message']}');
    return {
      'success': false,
      'message': data['message'] ?? 'Error al registrar usuario',
    };
  } catch (e) {
    print('Registration error: $e');
    _isLoading = false;
    notifyListeners();
    return {
      'success': false,
      'message': 'Error de conexión: ${e.toString()}',
    };
  }
}

   Future<void> logout() async {
    await _storage.deleteAll();
    _token = null;
    _currentUser = null;
    _lastActivity = null;
    notifyListeners();
  }
}