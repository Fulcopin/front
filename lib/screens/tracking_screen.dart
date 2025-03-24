import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _trackingController = TextEditingController();
  bool _isSearching = false;
  bool _hasResults = false;
  Map<String, dynamic>? _shipment;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _searchTracking() async {
    if (_trackingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un número de tracking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasResults = false;
      _shipment = null;
    });

    // Simular búsqueda
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSearching = false;
      _hasResults = true;
      _shipment = {
        'id': '1',
        'trackingNumber': _trackingController.text,
        'customer': 'Juan Pérez',
        'origin': 'Miami, FL',
        'destination': 'Ciudad de México, MX',
        'status': 'En tránsito',
        'date': '2025-03-14',
        'estimatedDelivery': '2025-03-17',
        'events': [
          {
            'date': '2025-03-14 09:15',
            'location': 'Miami, FL',
            'description': 'Paquete recibido en centro de distribución',
          },
          {
            'date': '2025-03-14 14:30',
            'location': 'Miami, FL',
            'description': 'Paquete procesado',
          },
          {
            'date': '2025-03-15 08:45',
            'location': 'Miami International Airport',
            'description': 'Paquete en tránsito',
          },
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Seguimiento de Envíos'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vacabox',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.currentUser?.name ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Envíos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/shipments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Seguimiento'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: const Text('Almacén'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/warehouse');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Facturación'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/billing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                authService.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rastrear paquete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa el número de seguimiento para rastrear el envío',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _trackingController,
                            decoration: const InputDecoration(
                              hintText: 'Ej. VB-12345678',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSearching ? null : _searchTracking,
                          child: _isSearching
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Rastrear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            // Escanear código QR
                          },
                          child: const Text('Escanear código QR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_hasResults && _shipment != null)
              _buildTrackingResult()
            else
              _buildRecentTrackings(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resultado de búsqueda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _hasResults = false;
                      _shipment = null;
                    });
                  },
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tracking: ${_shipment!['trackingNumber']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusBadge(_shipment!['status']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliente: ${_shipment!['customer']}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Origen: ${_shipment!['origin']}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Destino: ${_shipment!['destination']}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha de envío: ${_shipment!['date']}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entrega estimada: ${_shipment!['estimatedDelivery']}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Historial de seguimiento:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _shipment!['events'].length,
                    itemBuilder: (context, index) {
                      final event = _shipment!['events'][index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(top: 5, right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == 0 ? AppTheme.primaryColor : Colors.grey,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['date'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    event['location'],
                                    style: const TextStyle(
                                      color: AppTheme.mutedTextColor,
                                    ),
                                  ),
                                  Text(
                                    event['description'],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // Actualizar estado
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Actualizar estado'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Ver detalles completos
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ver detalles'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTrackings() {
    final recentTrackings = [
      {
        'tracking': 'VB-12345678',
        'status': 'En tránsito',
        'date': '15 Mar 2025',
      },
      {
        'tracking': 'VB-87654321',
        'status': 'Entregado',
        'date': '10 Mar 2025',
      },
      {
        'tracking': 'VB-23456789',
        'status': 'Procesando',
        'date': '05 Mar 2025',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Búsquedas recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTrackings.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final tracking = recentTrackings[index];
                return ListTile(
                  title: Text(
                    tracking['tracking']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${tracking['status']} - ${tracking['date']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      _trackingController.text = tracking['tracking']!;
                      _searchTracking();
                    },
                  ),
                  onTap: () {
                    _trackingController.text = tracking['tracking']!;
                    _searchTracking();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Entregado':
        color = Colors.green;
        break;
      case 'En tránsito':
        color = AppTheme.primaryColor;
        break;
      case 'Procesando':
        color = Colors.orange;
        break;
      case 'Retrasado':
        color = Colors.red;
        break;
      default:
        color = AppTheme.mutedTextColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

