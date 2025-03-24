import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import './image_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class ProductService {
  final String baseUrl = 'https://proyect-currier.onrender.com';
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



  // Método para agregar un producto
 Future<Product> addProduct(Product product) async {
  try {
    final token = await _storage.read(key: 'token');
    print('\n=== Token Debug ===');
    print('Raw token: $token');
    
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado');
    }

    // No Bearer prefix manipulation - send token as is
    final response = await http.post(
      Uri.parse('$baseUrl/user/RegistrarProducto'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,  // Send raw token
      },
      body: json.encode({
        'id_user': product.id_user,
        'nombre': product.nombre,
        'descripcion': product.descripcion,
        'peso': product.peso,
        'precio': product.precio,
        'cantidad': product.cantidad,
        'link': product.link,
        'imagenUrl': product.imagenUrl,
        'facturaUrl': product.facturaUrl,
      }),
    );

    print('\n=== Response Debug ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 403) {
      await _storage.delete(key: 'token');
      throw Exception('Sesión expirada. Por favor inicie sesión nuevamente.');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Product(
        id: data['id'] ?? '',
        id_user: product.id_user,
        nombre: product.nombre,
        descripcion: product.descripcion,
        peso: product.peso,
        precio: product.precio,
        cantidad: product.cantidad,
        link: product.link,
        imagenUrl: data['imagenUrl'] ?? product.imagenUrl,
        facturaUrl: data['facturaUrl'] ?? product.facturaUrl,
        fechaCreacion: DateTime.now(),
      );
    }
    
    throw Exception('Error del servidor: ${response.statusCode}');
  } catch (e) {
    print('Error in addProduct: $e');
    rethrow;
  }
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

