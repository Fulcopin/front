import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shipment_service.dart';

class ClientShipmentsOverview extends StatefulWidget {
  final Function(String) onShipmentTap;
  
  const ClientShipmentsOverview({
    Key? key,
    required this.onShipmentTap,
  }) : super(key: key);

  @override
  _ClientShipmentsOverviewState createState() => _ClientShipmentsOverviewState();
}

class _ClientShipmentsOverviewState extends State<ClientShipmentsOverview> {
  final ShipmentService _shipmentService = ShipmentService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _recentShipments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRecentShipments();
  }

  // Cargar los envíos recientes del usuario
  Future<void> _loadRecentShipments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obtener token de autenticación
      final token = await _storage.read(key: 'token');
      
      if (token == null) {
        setState(() {
          _errorMessage = 'No se encontró token de autenticación';
          _isLoading = false;
        });
        return;
      }

      // Usar la función existente para obtener los envíos
      final shipments = await _shipmentService.getUserShipmentsFromApi(token: token);
      
      // Tomar solo los 3 primeros envíos (los más recientes)
      final recentShipments = shipments.take(3).toList();
      
      if (recentShipments.isNotEmpty) {
        setState(() {
          _recentShipments = recentShipments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _recentShipments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando envíos recientes: $e');
      setState(() {
        _errorMessage = 'Error al cargar envíos: $e';
        _isLoading = false;
      });
    }
  }

  // Obtener color según el estado
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en tránsito':
      case 'en transito':
        return Colors.blue;
      case 'entregado':
        return Colors.green;
      case 'procesando':
        return Colors.orange;
      case 'en bodega':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Envíos Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadRecentShipments,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadRecentShipments,
                      child: Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else if (_recentShipments.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No tienes envíos recientes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentShipments.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final shipment = _recentShipments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    title: Text(
                      'Tracking: ${shipment['trackingNumber'] ?? shipment['id'] ?? 'No disponible'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('Fecha: ${shipment['date'] ?? 'No disponible'}'),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(shipment['status'] ?? 'Procesando').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(shipment['status'] ?? 'Procesando'),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            shipment['status'] ?? 'Procesando',
                            style: TextStyle(
                              color: _getStatusColor(shipment['status'] ?? 'Procesando'),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {
                        // Llamar a la función proporcionada para mostrar detalles
                        widget.onShipmentTap(shipment['id'] ?? '');
                      },
                    ),
                    onTap: () {
                      // Llamar a la función proporcionada para mostrar detalles
                      widget.onShipmentTap(shipment['id'] ?? '');
                    },
                  );
                },
              ),
              
            SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                icon: Icon(Icons.list_alt),
                label: Text('Ver todos mis envíos'),
                onPressed: () {
                  // Navegar a la página de todos los envíos
                  Navigator.pushNamed(context, '/my-shipments');
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}