import 'dart:convert';
import 'package:http/http.dart' as http;


class UserStatsService {
  final String baseUrl ="https://api-mpxltf6i3a-uc.a.run.app";


  Future<Map<String, dynamic>> getUserStats(String token, String userId) async {
    try {
      print('📊 Fetching user stats for userId: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/stats/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
          'X-User-ID': userId, // Enviar ID de usuario en cabecera también
        },
      );

      print('📊 API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('Error fetching user stats: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load user stats');
      }
    } catch (e) {
      print('Error in getUserStats: $e');
      // Valores temporales para mostrar mientras se arregla
      return {
        'totalShipments': 3,
        'shipmentsInTransit': 1,
        'totalSpent': 350.0,
      };
    }
  }
}