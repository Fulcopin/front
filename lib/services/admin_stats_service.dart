import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminStatsService {
  final String baseUrl ="https://proyect-currier.onrender.com";
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Get auth token
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verify data structure and provide defaults if necessary
        return {
          'totalUsers': data['totalUsers'] ?? 0,
          'totalProducts': data['totalProducts'] ?? 0,
          'totalShipments': data['totalShipments'] ?? 0,
          'pendingPayments': data['pendingPayments'] ?? 0,
          'productsInWarehouse': data['productsInWarehouse'] ?? 0,
          'productsInTransit': data['productsInTransit'] ?? 0,
          'productsDelivered': data['productsDelivered'] ?? 0,
          'revenue': data['revenue']?.toDouble() ?? 0.0,
        };
      } else {
        print('Error fetching admin stats: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load admin stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAdminStats: $e');
      // Return default values if there's an error
      return {
        'totalUsers': 0,
        'totalProducts': 0,
        'totalShipments': 0,
        'pendingPayments': 0,
        'productsInWarehouse': 0,
        'productsInTransit': 0,
        'productsDelivered': 0,
        'revenue': 0.0,
      };
    }
  }


Future<List<Map<String, dynamic>>> getMonthlyRevenue() async {
  try {
    // Get auth token
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats/monthly-revenue'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['monthlyData'] ?? []);
    } else {
      print('Error fetching monthly revenue: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load monthly revenue: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getMonthlyRevenue: $e');
    // Return empty data if there's an error
    return [];
  }
}
}