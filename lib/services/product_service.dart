import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import './image_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
class ProductService {
  final String baseUrl = 'https://api-mpxltf6i3a-uc.a.run.app';
  final _storage = const FlutterSecureStorage();
  // Datos simulados para productos
  final List<Product> _mockProducts = [
    Product(
      id:'1',
      id_user: '1',
      nombre: 'Smartphone XYZ',
      descripcion: 'Último modelo con cámara de alta resolución y batería de larga duración',
      peso: 0.2,
      precio: 899.99,
      cantidad: 1,
      fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Product(
      id: '2',
      id_user: '2',
      nombre: 'Laptop ABC',
      descripcion: 'Potente laptop para trabajo y gaming con procesador de última generación',
      peso: 2.5,
      precio: 1299.99,
      cantidad: 1,
      link: 'https://example.com/laptop',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Product(
      id: "3",
      id_user: '3',
      nombre: 'Auriculares Bluetooth',
      descripcion: 'Auriculares inalámbricos con cancelación de ruido y gran calidad de sonido',
      peso: 0.3,
      precio: 149.99,
      cantidad: 2,
      fechaCreacion: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];


  // Add initialization check
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'userId');
    return token != null && userId != null;
  }

  // Add debug method
  Future<void> _printAuthDebug() async {
    final token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'userId');
    print('Debug - Token: ${token?.substring(0, 10)}...');
    print('Debug - UserId: $userId');
  }
  Future<String?> getUserId() async {
    try {
      // First try to get from storage
      final userId = await _storage.read(key: 'userId');
      if (userId != null) return userId;

      // If not in storage, try to extract from token
      final token = await _storage.read(key: 'token');
      if (token != null) {
        final parts = token.split('.');
        if (parts.length > 1) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
          );
          final extractedUserId = payload['id'];
          
          // Cache userId for future use
          if (extractedUserId != null) {
            await _storage.write(key: 'userId', value: extractedUserId);
          }
          
          return extractedUserId;
        }
      }
      return null;
    } catch (e) {
      print('Error getting userId: $e');
      return null;
    }
  }
  Future<Map<String, dynamic>> generateCardPayment({
  required double subtotal,
  required String clientTransactionId,
  String? token,
}) async {
  try {
      String? authToken = token;
    if (authToken == null) {
      authToken = await _storage.read(key: 'token');
      if (authToken == null) {
        throw Exception('Token no encontrado');
      }
    }

    // 2. Imprimir información del token para diagnóstico
    print('Token usado (longitud: ${authToken.length}): ${authToken.substring(0, min(30, authToken.length))}...');
    
   
    // 4. Crear la petición con el token sin modificar
    final response = await http.post(
      Uri.parse('$baseUrl/user/GenerarPago'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authToken, // Usar el token tal cual está almacenado
      },
      body: jsonEncode({
        'ClientTransactionID': clientTransactionId,
        'subtotal': double.parse(subtotal.toStringAsFixed(2)), 
      }),
    );

    print('URL utilizada: $baseUrl/user/GenerarPago');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      // Error específico para problemas de autenticación
      throw Exception('Error de autenticación: Token inválido o expirado. Por favor, vuelve a iniciar sesión.');
    }
    
    throw Exception('Error al generar pago: ${response.statusCode}');
  } catch (e) {
    print('Error en generateCardPayment: $e');
    rethrow;
  }
}
Future<Map<String, dynamic>> checkPaymentStatus(String clientTransactionId) async {
  try {
    final authHeader = "Bearer d2bbkrY0ilEa-mEhSLXbXSJQqcJGAotRraGLccuTFt6z51EE4GcBr7wa5ZROhygufqQns2rquCPmCPYtDOAJlVq_w-spiUCMdzUpCHZcJS2ACYfo70RV7HCVWj8IBnbEDOCWQfDgMjz5_NBcRKN0Fk89ZD14bDLfiX5ebYnN2rIq1onvnwzW9Cz7vAd_HKVjTlMH_MfJRcKpdf7oOW0xmKw4XxA_DhgbfZQ0tUX49_xGCVlYiTncKQsv413nLlCadgTEUydCYY5Ruzo4ZOISB7C9zR6Vl5cvlL-P3hdRnu1mJOIwDyaNkJ17wOh8dWen0n26e_7YZvYQYuwNbZye3hY5O0M";
    
    final response = await http.get(
      Uri.parse('https://pay.payphonetodoesposible.com/api/Sale/client/$clientTransactionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
    );

    print('URL verificación: https://pay.payphonetodoesposible.com/api/Sale/client/$clientTransactionId');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      // Procesar la respuesta
      final dynamic decodedData = json.decode(response.body);
      
      // If the response is a list, get the first item
      if (decodedData is List && decodedData.isNotEmpty) {
        print("Respuesta recibida como lista con ${decodedData.length} elementos");
        
        // Extract the first item and pass it through directly
        Map<String, dynamic> transactionData = Map<String, dynamic>.from(decodedData[0] as Map);
        
        // Check if it's approved
        bool isApproved = transactionData['transactionStatus'] == "Approved";
        
        // Return the COMPLETE transaction data with success added
        transactionData['success'] = true;
        transactionData['isApproved'] = isApproved;
        
        return transactionData; // Return the full data directly
      } 
      else if (decodedData is Map) {
        print("Respuesta recibida como objeto único");
        
        // Convert to proper Map<String, dynamic>
        Map<String, dynamic> transactionData = Map<String, dynamic>.from(decodedData as Map);
        
        // Check if it's approved
        bool isApproved = transactionData['transactionStatus'] == "Approved";
        
        // Return the COMPLETE transaction data with success added
        transactionData['success'] = true;
        transactionData['isApproved'] = isApproved;
        
        return transactionData; // Return the full data directly
      }
      else {
        print("Formato de respuesta no reconocido: ${decodedData.runtimeType}");
        return {
          'success': false,
          'message': 'Formato de respuesta no reconocido',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Error al verificar pago: ${response.statusCode}',
        'statusCode': response.statusCode,
        'responseBody': response.body,
      };
    }
  } catch (e) {
    print('Error en checkPaymentStatus: $e');
    return {
      'success': false,
      'message': 'Error de verificación: $e',
    };
  }
}
Future<Map<String, dynamic>> registerPayment(
    String clientTransactionId, 
    double amount, 
    List<String> productIds,
    Map<String, dynamic> paymentData
) async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token no encontrado');
    }
    
    final cardType = paymentData['cardType'] ?? 'Desconocido';
     final random = Random();
    final randomAuth = 'AUTH${random.nextInt(1000000)}';
    final randomDigits = '${1000 + random.nextInt(9000)}';
    
    final email = paymentData['email'] ?? 'cliente@example.com';
    final lastDigits = paymentData['lastDigits']?.toString() ?? randomDigits;
    final cardBrand = paymentData['cardBrand']?.toString() ?? 'Visa';
    final authCode = paymentData['authorizationCode']?.toString() ?? randomAuth;
    final status = paymentData['transactionStatus']?.toString() ?? 'Approved';
    final document = paymentData['document']?.toString() ?? '1234567890';
    final date = paymentData['date']?.toString() ?? DateTime.now().toIso8601String();
    // Crear el objeto de datos para registrar el pago
    final paymentDetails = {
      'monto': amount,
      'metodo': 'tarjeta',
      'productos': productIds,
      'transactionId': clientTransactionId,
      'detalles': {
        'email': email,
        'cardType': cardType,
        'lastDigits': lastDigits,
        'cardBrand': cardBrand,
        'authorizationCode': authCode,
        'transactionStatus': status,
        'cedula': document,
        'amount': amount,
        'date': date,
      }
    };
    print('Enviando detalles de pago: $paymentDetails');
    
    // Enviar solicitud para registrar el pago
    final response = await http.post(
      Uri.parse('$baseUrl/user/RegistrarPago'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode(paymentDetails),
    );
    
    print('Respuesta registro pago: ${response.statusCode}');
    print('Respuesta cuerpo: ${response.body}');
    
   if (response.statusCode == 200) {
  final responseData = json.decode(response.body);
  
  // IMPORTANT: Store the payment ID returned by the server
  if (responseData['pagoId'] != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastPaymentId', responseData['pagoId'].toString());
    print('ID de pago guardado para envío: ${responseData['pagoId']}');
  }
  
  return {
    'success': true,
    'data': responseData,
    'pagoId': responseData['pagoId']
  };
} else {
      return {
        'success': false,
        'message': 'Error al registrar pago: ${response.statusCode}',
      };
    }
  } catch (e) {
    print('Error en registerPayment: $e');
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

// Añade este método a tu ProductService
Future<List<Map<String, dynamic>>> getProductsInWarehouse({required String token}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/productos/en-bodega'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data['productos'] != null && data['productos'] is List) {
        return List<Map<String, dynamic>>.from(data['productos']);
      }
      
      return [];
    } else {
      print('Error fetching warehouse products: ${response.statusCode}');
      throw Exception('Error al obtener productos en bodega');
    }
  } catch (e) {
    print('Error in getProductsInWarehouse: $e');
    throw Exception('Error al obtener productos en bodega: $e');
  }
}
  Future<List<Product>> getProducts() async {
   try {
    final token = await _storage.read(key: 'token');
    final userId = await getUserId();
    
    if (token == null || userId == null) {
      throw Exception('Token o userId no encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/productos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
        
      },
    );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 500) {
        final errorData = json.decode(response.body);
        if (errorData['error']?.contains('requires an index')) {
          throw Exception(
            'Se requiere crear un índice en Firebase. Por favor contacte al administrador.'
          );
        }
      }

      if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Parsed data length: ${data.length}');

      return data.map((item) {
        // Debug each product parsing
        print('Processing item with ID: ${item['id']}');
        
        
        final product = Product(
          id: item['id'] ?? '',
          id_user: item['id_user'] ?? '',
          nombre: item['nombre'] ?? '',
          descripcion: item['descripcion'] ?? '',
          peso: double.parse(item['peso']?.toString() ?? '0'),
          precio: double.parse(item['precio']?.toString() ?? '0'),
          cantidad: int.parse(item['cantidad']?.toString() ?? '0'),
          link: item['link'],
          imagenUrl: item['imagenUrl'],
          facturaUrl: item['facturaUrl'],
          fechaCreacion: DateTime.parse(item['fechaCreacion'] ?? DateTime.now().toIso8601String()),
          estado: item['estado'] ?? item['Estado'] ?? 'No llegado',
        );
        
        print('Processed product: ${product.nombre}');
        return product;
      }).toList();
    }
      throw Exception('Error del servidor: ${response.statusCode}');
    } catch (e) {
      print('Error getting products: $e');
      rethrow;
    }
  }

// Add required imports


// Add this method to your ProductService class
Future<Map<String, dynamic>> getAdminProducts({int page = 1, int limit = 10}) async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    // Ensure token has Bearer prefix
    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    
    print('Fetching admin products, page: $page, limit: $limit');

    final response = await http.get(
      Uri.parse('$baseUrl/admin/MostrarProductos?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
    );

    print('Admin products response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Got ${data['data'].length} products of ${data['total']} total');
      
      return {
        'products': (data['data'] as List).map((item) => Product(
          id: item['id'] ?? '',
          id_user: item['usuario']?['id'] ?? '',
          nombre: item['nombre'] ?? '',
          descripcion: item['descripcion'] ?? '',
          peso: double.tryParse(item['peso']?.toString() ?? '0') ?? 0,
          precio: double.tryParse(item['precio']?.toString() ?? '0') ?? 0,
          cantidad: int.tryParse(item['cantidad']?.toString() ?? '0') ?? 0,
          link: item['link'],
          imagenUrl: item['imagenUrl'],
          facturaUrl: item['facturaUrl'],
          fechaCreacion: item['fechaCreacion'] != null 
            ? DateTime.parse(item['fechaCreacion'])
            : DateTime.now(),
          usuario: item['usuario'],
          estado: item['estado'] ?? 'No llegado',
        )).toList(),
        'page': data['page'],
        'limit': data['limit'],
        'total': data['total'],
      };
    }
    
    if (response.statusCode == 403) {
      throw Exception('No tienes permisos de administrador');
    }
    
    throw Exception('Error del servidor: ${response.statusCode}');
  } catch (e) {
    print('Error getting admin products: $e');
    rethrow;
  }
}
Future<Product> addProduct(Product product) async {
  try {
    // Get both token and userId
    final token = await _storage.read(key: 'token');
    final userId = await getUserId();
    
    print('\n=== Authentication Debug ===');
    print('Token exists: ${token != null}');
    print('UserID: $userId');
    
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado');
    }
    
    if (userId == null || userId.isEmpty) {
      throw Exception('ID de usuario no encontrado');
    }
    
    // Ensure product has the correct user ID
    Product productToAdd = product;
    if (product.id_user == null || product.id_user.isEmpty) {
      productToAdd = Product(
        id: product.id,
        id_user: userId, // Set the user ID from storage
        nombre: product.nombre,
        descripcion: product.descripcion,
        peso: product.peso,
        precio: product.precio,
        cantidad: product.cantidad,
        link: product.link,
        imagenUrl: product.imagenUrl,
        facturaUrl: product.facturaUrl,
        fechaCreacion: product.fechaCreacion,
        estado: 'No llegado',
      );
    }

    // Check if token needs 'Bearer' prefix (depends on your backend)
    final authHeader = token.startsWith('Bearer ') ? token : token;
    
    final response = await http.post(
      Uri.parse('$baseUrl/user/RegistrarProducto'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: json.encode({
        'id_user': productToAdd.id_user,
        'nombre': productToAdd.nombre,
        'descripcion': productToAdd.descripcion,
        'peso': productToAdd.peso,
        'precio': productToAdd.precio,
        'cantidad': productToAdd.cantidad,
        'link': productToAdd.link ?? '',
        'imagenUrl': productToAdd.imagenUrl ?? '',
        'facturaUrl': productToAdd.facturaUrl ?? '',
         'estado': productToAdd.estado,
      }),
    );

    print('\n=== Response Debug ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 403 || response.statusCode == 401) {
      // Try to refresh token before giving up (implement token refresh if needed)
      throw Exception('Sesión expirada. Por favor inicie sesión nuevamente.');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Product(
        id: data['id'] ?? '',
        id_user: userId, // Use the verified user ID
        nombre: productToAdd.nombre,
        descripcion: productToAdd.descripcion,
        peso: productToAdd.peso,
        precio: productToAdd.precio,
        cantidad: productToAdd.cantidad,
        link: productToAdd.link,
        imagenUrl: data['imagenUrl'] ?? productToAdd.imagenUrl,
        facturaUrl: data['facturaUrl'] ?? productToAdd.facturaUrl,
        fechaCreacion: DateTime.now(),
        estado: 'No llegado',
      );
    }
    
    throw Exception('Error del servidor: ${response.statusCode}');
  } catch (e) {
    print('Error in addProduct: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> getProductStatusHistory(String productId) async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    
    final response = await http.get(
      Uri.parse('$baseUrl/admin/HistorialEstadosProducto/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['historial'] ?? []);
    }
    
    throw Exception('Error del servidor: ${response.statusCode}');
  } catch (e) {
    print('Error getting product status history: $e');
    rethrow;
  }
}// Add this method right after your getAdminProducts method

// Add this method to your ProductService class
Future<bool> sendEmailNotification({
  required String email,
  required String productName,
  required String status,
  String? additionalMessage,
}) async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    
    print('Sending email notification to: $email');
    
    // Create HTML content for the email
    final htmlContent = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 5px;">
        <h2 style="color: #2c3e50; text-align: center;">Actualización de Estado</h2>
        <p style="font-size: 16px; line-height: 1.5;">Estimado cliente,</p>
        <p style="font-size: 16px; line-height: 1.5;">Le informamos que su producto "<strong>${productName}</strong>" ha cambiado su estado a:</p>
        <p style="font-size: 18px; text-align: center; margin: 20px 0; padding: 10px; background-color: #f8f9fa; border-radius: 3px; color: #2c3e50;"><strong>${status}</strong></p>
        ${additionalMessage != null ? '<p style="font-size: 16px; line-height: 1.5;">${additionalMessage}</p>' : ''}
        <p style="font-size: 16px; line-height: 1.5;">Si tiene alguna pregunta, no dude en contactarnos.</p>
        <p style="font-size: 16px; line-height: 1.5; margin-top: 30px;">Saludos cordiales,<br>Equipo de Alerta Bodega</p>
      </div>
    ''';

    final response = await http.post(
      Uri.parse('$baseUrl/api/send-email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: json.encode({
        'to': email,
        'subject': 'Actualización: $productName',
        'html': htmlContent,
        'text': 'Su producto $productName ahora está en estado: $status. ${additionalMessage ?? ''}'
      }),
    );
    
    print('Email notification response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('Email notification sent successfully');
      return true;
    } else {
      print('Error sending email notification: ${response.body}');
      return false;
    }
  } catch (e) {
    print('Exception sending email notification: $e');
    return false;
  }
}
Future<Product> addProductAdmin(Product product) async {
  try {
    final token = await _storage.read(key: 'token');
    
    print('\n=== Admin Product Creation ===');
    print('Token exists: ${token != null}');
    
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado');
    }
    
    // Make sure token includes 'Bearer ' prefix if your auth middleware expects it
    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    
    final requestData = {
      'nombre': product.nombre,
      'descripcion': product.descripcion,
      'peso': product.peso,
      'precio': product.precio,
      'cantidad': product.cantidad,
      'link': product.link,
      'imagenUrl': product.imagenUrl,
      'facturaUrl': product.facturaUrl,
      'id_user': product.id_user  // This is needed but handled by backend via req.user.id
    };
    
    print('Sending data: ${json.encode(requestData)}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/admin/RegistrarProductos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
        
      },
      body: json.encode(requestData),
    );
    
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('userRole') ?? await _storage.read(key: 'role');
      if (role != 'ADMIN') {
        throw Exception('No tienes permisos de administrador');
      }
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Product(
        id:  '',
        id_user: product.id_user,
        nombre: product.nombre,
        descripcion: product.descripcion,
        peso: product.peso,
        precio: product.precio,
        cantidad: product.cantidad,
        link: product.link,
        imagenUrl: product.imagenUrl,
        facturaUrl: product.facturaUrl,
        fechaCreacion: product.fechaCreacion,
        estado: data['estado'] ?? 'No llegado',
      );
    }
    
    throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
  } catch (e) {
    print('Error in addProductAdmin (detailed): $e');
    rethrow;
  }
}
Future<List<Map<String, dynamic>>> getWarehouseProductsByUser(String userId, {required String token}) async {
  try {
    print('Fetching warehouse products for user: $userId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/admin/productos/usuario/$userId/en-bodega'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
    
    print('Warehouse products response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data['productos'] != null && data['productos'] is List) {
        return List<Map<String, dynamic>>.from(data['productos']);
      } else if (data['items'] != null && data['items'] is List) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      
      // If we got here, the data structure is different from expected
      // Try to extract any array we can find
      for (var key in data.keys) {
        if (data[key] is List) {
          return List<Map<String, dynamic>>.from(data[key]);
        }
      }
      
      print('Unexpected response structure: $data');
      return [];
    } else {
      print('Error fetching user warehouse products: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Error al obtener productos en bodega del usuario: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getWarehouseProductsByUser: $e');
    throw Exception('Error al obtener productos en bodega del usuario: $e');
  }
}

// Add method to update product status
Future<bool> updateProductStatusUser(String productId, String newStatus, {required String token}) async {
  try {
    print('Updating product $productId status to: $newStatus');
    
    final response = await http.put(
      Uri.parse('$baseUrl/admin/productos/$productId/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode({'estado': newStatus}),
    );
    
    if (response.statusCode == 200) {
      print('Product status updated successfully');
      return true;
    } else {
      print('Error updating product status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error in updateProductStatus: $e');
    return false;
  }
}
Future<bool> updateProductStatus(String productId, String newStatus) async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    
    print('===== Status Update API Call =====');
    print('URL: $baseUrl/admin/ActualizarEstadoProducto/$productId');
    print('Headers: Authorization: ${authHeader.substring(0, 20)}...');
    print('Body: {"estado": "$newStatus"}');

    final response = await http.put(
      Uri.parse('$baseUrl/admin/ActualizarEstadoProducto/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: json.encode({
        'estado': newStatus,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    
    throw Exception('Error del servidor: ${response.statusCode}');
  } catch (e) {
    print('Error updating product status: $e');
    rethrow;
  }
}

// Método mejorado para actualizar estado como usuario
Future<bool> updateProductStatusAsUser(String productId, String newStatus) async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      print('No se encontró token de autenticación');
      return false;
    }

    // Asegurarse de que el token tenga el formato correcto
    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    
    print('===== Status Update User API Call =====');
    print('URL: $baseUrl/user/ActualizarEstadoProducto/$productId');
    print('Body: {"estado": "$newStatus"}');

    final response = await http.put(
      Uri.parse('$baseUrl/user/ActualizarEstadoProducto/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: json.encode({
        'estado': newStatus,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else if (response.statusCode == 403) {
      // Si hay un error de permisos, intenta con la ruta de admin como fallback
      print('Error de permisos. Intentando con ruta alternativa...');
      return await updateProductStatus(productId, newStatus);
    }
    
    return false;
  } catch (e) {
    print('Error updating product status as user: $e');
    return false;
  }
}

// Add to your ProductService class
Future<bool> updateProduct(Product product) async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado');
    }
    
    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    
    final response = await http.put(
      Uri.parse('$baseUrl/admin/productos/${product.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: json.encode({
        'nombre': product.nombre,
        'descripcion': product.descripcion,
        'peso': product.peso,
        'precio': product.precio,
        'cantidad': product.cantidad,
        'link': product.link,
      }),
    );
    
    if (response.statusCode == 200) {
      return true;
    }
    
    throw Exception('Error al actualizar producto: ${response.statusCode} - ${response.body}');
  } catch (e) {
    print('Error en updateProduct: $e');
    rethrow;
  }
}
// Método para marcar productos como pagados usando la ruta de usuario
Future<bool> markProductsAsPaidAsUser(List<String> productIds) async {
  bool allSuccessful = true;
  
  for (String productId in productIds) {
    try {
      final success = await updateProductStatusAsUser(productId, 'Pagado');
      if (!success) {
        print('No se pudo actualizar el producto $productId a estado Pagado');
        allSuccessful = false;
      } else {
        print('Producto $productId marcado como Pagado correctamente');
      }
    } catch (e) {
      print('Error al marcar producto $productId como pagado: $e');
      allSuccessful = false;
    }
  }
  
  return allSuccessful;
}
  // Método para eliminar un producto
  Future<void> deleteProduct(String id) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    _mockProducts.removeWhere((product) => product.id_user == id);
  }
  Future<List<Product>> getUserProducts() async {
  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    print('\n=== Getting User Products ===');
    print('Using token: $token');

    final response = await http.get(
      Uri.parse('$baseUrl/user/productos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Product(
        id: item['id'] ?? '',
        id_user: item['Id_user'] ?? '',
        nombre: item['Nombre'] ?? '',
        descripcion: item['Descripcion'] ?? '',
        peso: double.parse(item['Peso']?.toString() ?? '0'),
        precio: double.parse(item['Precio']?.toString() ?? '0'),
        cantidad: int.parse(item['Cantidad']?.toString() ?? '0'),
        link: item['Link'],
        imagenUrl: item['ImagenUrl'],
        facturaUrl: item['FacturaUrl'],
        fechaCreacion: item['FechaCreacion'] != null 
          ? DateTime.parse(item['FechaCreacion'])
          : DateTime.now(),
      )).toList();
    }
    
    throw Exception('Error: ${response.statusCode}');
  } catch (e) {
    print('Error getting user products: $e');
    rethrow;
  }
}
}

