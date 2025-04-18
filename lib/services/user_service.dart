import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class UserService {
  final String baseUrl = 'http://localhost:5000';
  final _storage = const FlutterSecureStorage();
   

  // Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['usuarios'] ?? []);
      } else {
        print('Error fetching users: ${response.statusCode}');
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllUsers: $e');
      throw Exception('Error al obtener usuarios: $e');
    }
  }
  
  // Update user (admin only)
  Future<Map<String, dynamic>> updateUser({
    required String token,
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/usuarios/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Error updating user: ${response.statusCode}');
        throw Exception('Error al actualizar usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateUser: $e');
      throw Exception('Error al actualizar usuario: $e');
    }
  }
  
  // Update user password (admin only)
  Future<Map<String, dynamic>> updateUserPassword({
    required String token,
    required String userId,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/usuarios/$userId/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode({'password': newPassword}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Error updating password: ${response.statusCode}');
        throw Exception('Error al actualizar contraseña: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateUserPassword: $e');
      throw Exception('Error al actualizar contraseña: $e');
    }
  }

  // Get user's warehouse products (admin only)
  Future<List<Map<String, dynamic>>> getUserWarehouseProducts({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/productos/usuario/$userId/en-bodega'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['productos'] ?? []);
      } else {
        print('Error fetching user products: ${response.statusCode}');
        throw Exception('Error al obtener productos del usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserWarehouseProducts: $e');
      throw Exception('Error al obtener productos del usuario: $e');
    }
  }


  // Get user details by ID
  Future<Map<String, dynamic>> getUserDetails(String userId, {required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/usuarios/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching user details: ${response.statusCode}');
        throw Exception('Error al obtener detalles del usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserDetails: $e');
      throw Exception('Error al obtener detalles del usuario: $e');
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching user profile: ${response.statusCode}');
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getCurrentUserProfile: $e');
      throw Exception('Error al obtener perfil: $e');
    }
  }

  // Update user address
  Future<bool> updateUserAddress({
    required String address,
    required String city,
    required String country,
    String? postalCode,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final addressData = {
        'direccion': address,
        'ciudad': city,
        'pais': country,
        if (postalCode != null) 'codigoPostal': postalCode,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/user/actualizarDireccion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode(addressData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in updateUserAddress: $e');
      return false;
    }
  }
}