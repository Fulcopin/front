import 'dart:async';
import 'dart:math';

class StatsService {
  // Método para obtener estadísticas generales
  Future<Map<String, dynamic>> getGeneralStats() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'totalUsers': 156,
      'totalProducts': 423,
      'totalShipments': 289,
      'pendingPayments': 42,
      'productsInWarehouse': 87,
      'productsInTransit': 134,
      'productsDelivered': 202,
      'revenue': 45231.75,
      'averageShipmentTime': 5.3, // días
    };
  }

  // Método para obtener datos de envíos por mes
  Future<List<Map<String, dynamic>>> getShipmentsByMonth() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    final now = DateTime.now();
    final random = Random();
    
    // Generar datos para los últimos 6 meses
    final List<Map<String, dynamic>> data = [];
    
    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;
      
      final monthName = _getMonthName(adjustedMonth);
      
      data.add({
        'month': monthName,
        'year': year,
        'shipments': 30 + random.nextInt(40),
        'revenue': 5000 + random.nextInt(10000),
      });
    }
    
    return data;
  }

  // Método para obtener datos de productos por categoría
  Future<List<Map<String, dynamic>>> getProductsByCategory() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      {'category': 'Electrónicos', 'count': 156, 'percentage': 36.9},
      {'category': 'Ropa', 'count': 98, 'percentage': 23.2},
      {'category': 'Hogar', 'count': 67, 'percentage': 15.8},
      {'category': 'Juguetes', 'count': 45, 'percentage': 10.6},
      {'category': 'Otros', 'count': 57, 'percentage': 13.5},
    ];
  }

  // Método para obtener datos de usuarios más activos

  // Método para obtener datos de productos pendientes de pago
  Future<List<Map<String, dynamic>>> getPendingPaymentProducts() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      {
        'id': '10',
        'name': 'Smartphone Premium',
        'user': 'María González',
        'userId': '2',
        'arrivalDate': '2025-03-25',
        'price': 899.99,
        'status': 'En bodega',
      },
      {
        'id': '11',
        'name': 'Laptop Ultradelgada',
        'user': 'Carlos Rodríguez',
        'userId': '3',
        'arrivalDate': '2025-03-24',
        'price': 1299.99,
        'status': 'En bodega',
      },
      {
        'id': '12',
        'name': 'Auriculares Inalámbricos',
        'user': 'Ana Martínez',
        'userId': '4',
        'arrivalDate': '2025-03-23',
        'price': 149.99,
        'status': 'En bodega',
      },
      {
        'id': '13',
        'name': 'Tablet Pro',
        'user': 'Roberto Sánchez',
        'userId': '5',
        'arrivalDate': '2025-03-22',
        'price': 599.99,
        'status': 'En bodega',
      },
      {
        'id': '14',
        'name': 'Cámara Digital',
        'user': 'Laura Gómez',
        'userId': '6',
        'arrivalDate': '2025-03-21',
        'price': 449.99,
        'status': 'En bodega',
      },
    ];
  }

  // Método para obtener datos de envíos recientes
  

  // Método auxiliar para obtener el nombre del mes
  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Enero';
      case 2: return 'Febrero';
      case 3: return 'Marzo';
      case 4: return 'Abril';
      case 5: return 'Mayo';
      case 6: return 'Junio';
      case 7: return 'Julio';
      case 8: return 'Agosto';
      case 9: return 'Septiembre';
      case 10: return 'Octubre';
      case 11: return 'Noviembre';
      case 12: return 'Diciembre';
      default: return '';
    }
  }
}

