import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  final String _baseUrl = 'https://api-mpxltf6i3a-uc.a.run.app'; // Update with your backend URL
  //static const String CLIENT_SECRET_KEY = '2454619e5c46941ea1be0cebb2df67577070f3861a7f5df8dd8ca0c81deaf4fe';
  static const String ADMIN_SECRET_KEY = '22765924bc2a9a1485a2d9473399d9b6b3578e1f253baaf2ba81199982a57cf535dfecf487946efd51f85c613f6ac78882fe9b2246f4552058805da328682dbd'; 
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

 String? _userId;
  DateTime? _lastValidation;
  static const validationInterval = Duration(minutes: 5);

  final _storage = const FlutterSecureStorage();
   String? _sessionId;
  String? _token;
static const sessionTimeout = Duration(hours: 24);
 DateTime? _lastActivity;

   // Remove bool getter
Future<bool> isAdmin() async {
  try {
    // Check role from secure storage
    final role = await _storage.read(key: 'role');
    if (role == null) return false;
    
    // Validate token expiration
    final lastActivity = await _storage.read(key: 'lastActivity');
    if (lastActivity != null) {
      final lastActivityDate = DateTime.parse(lastActivity);
      if (DateTime.now().difference(lastActivityDate) > sessionTimeout) {
        return false;
      }
    }

    return role == 'ADMIN';
  } catch (e) {
    print('Error checking admin role: $e');
    return false;
  }
}

  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }
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

  // Update the login method to handle admin and client tokens correctly

Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    _isLoading = true;
    notifyListeners();

    // Log the request details for debugging
    print('Login request:');
    print('URL: $_baseUrl/Login');
    print('Email: $email');
    print('Password length: ${password.length}');

    final response = await http.post(
      Uri.parse('$_baseUrl/Login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email.trim(),  // Trim whitespace
        'password': password,
      }),
    );

    print('Login status code: ${response.statusCode}');
    print('Login response: ${response.body}');
    
    // Parse JSON response ONCE
    final responseData = json.decode(response.body);
     final prefs = await SharedPreferences.getInstance();
    if (response.statusCode == 200 && responseData['token'] != null) {
      final token = responseData['token'];
      
      // Get user data
      final direccion = responseData['direccion']?.toString() ?? '';
      final ciudad = responseData['ciudad']?.toString() ?? '';
      final pais = responseData['pais']?.toString() ?? '';
      final userid = responseData['id']?.toString() ?? '';
      final nombre = responseData['nombre']?.toString() ?? '';
      final apellido = responseData['apellido']?.toString() ?? '';
      final telefono = responseData['telefono']?.toString() ?? '';
      
          print('Dirección: $direccion');
          
          print('Ciudad: $ciudad');
          print('País: $pais');
          await prefs.setString('userAddress', direccion);
          await prefs.setString('userCity', ciudad);
          await prefs.setString('userCountry', pais);
          await prefs.setString('idUser', userid);
          await prefs.setString('name', nombre);
          await prefs.setString('telefono', telefono);
          await prefs.setString('apellido',apellido);
          final fullAddress = [direccion, ciudad, pais]
          .where((part) => part.isNotEmpty)
          .join(', ');
      if (fullAddress.isNotEmpty) {
      await prefs.setString('userFullAddress', fullAddress);
      print('Dirección completa guardada: $fullAddress');
    }
      final isAdmin = responseData['message'] == 'Login Exitoso';
      print('User role detected: ${isAdmin ? "ADMIN" : "CLIENTE"}');
      
      // Store token and role securely
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'role', value: isAdmin ? 'ADMIN' : 'CLIENTE');
      await _storage.write(key: 'name', value: nombre);
      // Store user ID if available
      if (responseData['id'] != null) {
        await _storage.write(key: 'userId', value: responseData['id'].toString());
        print('Stored user ID: ${responseData['id']}');
      } 
      
      // Store session info
      _lastActivity = DateTime.now();
      await _storage.write(
        key: 'lastActivity',
        value: _lastActivity!.toIso8601String()
      );
      await _storage.write(
        key: 'sessionDuration',
        value: (4 * 60 * 60 * 1000).toString()
      );

      _token = token;
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'isAdmin': isAdmin,
        'token': token
      };
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': responseData['message'] ?? 'Error de autenticación'};
  } catch (e) {
    print('Login error: $e');
    _isLoading = false;
    notifyListeners();
    return {'success': false, 'error': e.toString()};
  }
}
// Update the method to get auth headers
Future<Map<String, String>> getAuthHeaders() async {
  final token = await _storage.read(key: 'token');
  
  if (token == null) {
    throw Exception('Token no encontrado');
  }
  
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}
// Add this property and method to your AuthService class
// Get token without validation for internal use
Future<String?> getAuthToken() async {
  return await _storage.read(key: 'token');
}

// Get role directly from storage, not from API


Future<String?> getUserId() async {
  // First check if we have the user ID in memory
  if (_userId != null && _userId!.isNotEmpty) {
    return _userId;
  }
  
  // If not in memory, try to get it from storage
  final storedId = await _storage.read(key: 'userId');
  if (storedId != null && storedId.isNotEmpty) {
    _userId = storedId; // Save to memory for next time
    return storedId;
  }
  
  print('Warning: No user ID found');
  return null;
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
// Add this method to your AuthService class

// Add or modify in your AuthService class

// Increased session duration (8 hours)
final int _sessionDurationMillis = 8 * 60 * 60 * 1000; 
// Complete the initializeSession method you've already started

Future<void> initializeSession() async {
  try {
    print('Initializing user session...');
    
    // Load all authentication data
    _token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'userId');
    final roleValue = await _storage.read(key: 'role');
    final lastActivityStr = await _storage.read(key: 'lastActivity');
    
    print('Auth data loaded - Token exists: ${_token != null}, UserID: $userId, Role: $roleValue');
    
    if (_token != null) {
      // Store user ID in a class property for easy access
      if (userId != null) {
        _userId = userId; // Add a _userId property to your class
      }
      
      // Set last activity
      if (lastActivityStr != null) {
        _lastActivity = DateTime.parse(lastActivityStr);
      } else {
        _lastActivity = DateTime.now();
        await _storage.write(
          key: 'lastActivity',
          value: _lastActivity!.toIso8601String()
        );
      }
      
      print('Session initialized successfully');
      notifyListeners();
    } else {
      print('No valid token found during initialization');
    }
  } catch (e) {
    print('Error initializing session: $e');
  }
}

// Add this method to check and refresh token if needed
Future<bool> validateSession() async {
  try {
    final token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'userId');
    
    if (token == null || userId == null) {
      return false;
    }
    
    // Update last activity
    _lastActivity = DateTime.now();
    await _storage.write(
      key: 'lastActivity',
      value: _lastActivity!.toIso8601String()
    );
    
    return true;
  } catch (e) {
    print('Error validating session: $e');
    return false;
  }
}
  Future<bool> checkAuthStatus() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return false;

      final isValid = await validateSession();
      if (!isValid) return false;

      return true;
    } catch (e) {
      print('Auth status check error: $e');
      return false;
    }
  }
  Future<String?> getUserRole() async {
    return await _storage.read(key: 'role');
  }


  void updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
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