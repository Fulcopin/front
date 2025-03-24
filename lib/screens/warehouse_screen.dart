import 'package:flutter/material.dart';
import '../theme.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Almacén'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Inventario'),
            Tab(text: 'Recepción'),
            Tab(text: 'Despacho'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar producto, ubicación...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryTab(),
                _buildReceivingTab(),
                _buildDispatchTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción según la pestaña activa
          switch (_tabController.index) {
            case 0:
              _showAddProductDialog();
              break;
            case 1:
              _showReceiveProductDialog();
              break;
            case 2:
              _showDispatchProductDialog();
              break;
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInventoryTab() {
  
    final inventory = [
    
    
      {
        'id': '1',
        'sku': 'PROD-001',
        'name': 'Smartphone XYZ',
        'category': 'Electrónicos',
        'quantity': '15',
        'location': 'A-12-3',
        'status': 'Disponible',
      },
      {
        'id': '2',
        'sku': 'PROD-002',
        'name': 'Laptop ABC',
        'category': 'Electrónicos',
        'quantity': '8',
        'location': 'A-14-2',
        'status': 'Disponible',
      },
      {
        'id': '3',
        'sku': 'PROD-003',
        'name': 'Zapatillas Deportivas',
        'category': 'Ropa',
        'quantity': '25',
        'location': 'B-03-1',
        'status': 'Disponible',
      },
      {
        'id': '4',
        'sku': 'PROD-004',
        'name': 'Cámara Digital',
        'category': 'Electrónicos',
        'quantity': '5',
        'location': 'A-11-4',
        'status': 'Bajo stock',
      },
      {
        'id': '5',
        'sku': 'PROD-005',
        'name': 'Reloj Inteligente',
        'category': 'Accesorios',
        'quantity': '0',
        'location': 'C-02-2',
        'status': 'Sin stock',
      },
    ];

    final searchQuery = _searchController.text.toLowerCase();
    final filteredInventory = inventory.where((item) {
      return item['sku']!.toLowerCase().contains(searchQuery) ||
          item['name']!.toLowerCase().contains(searchQuery) ||
          item['category']!.toLowerCase().contains(searchQuery) ||
          item['location']!.toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredInventory.isEmpty) {
      return const Center(
        child: Text('No se encontraron productos'),
      );
    }

    return ListView.builder(
      itemCount: filteredInventory.length,
      itemBuilder: (context, index) {
        final item = filteredInventory[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              '${item['sku']} - ${item['name']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Categoría: ${item['category']} | Ubicación: ${item['location']}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInventoryStatusBadge(item['status']!),
                const SizedBox(width: 8),
                Text(
                  'Cant: ${item['quantity']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    // Editar producto
                  },
                ),
              ],
            ),
            onTap: () {
              // Ver detalles del producto
            },
          ),
        );
      },
    );
  }

  Widget _buildReceivingTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestión de Recepción de Mercancía',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registre la entrada de productos al almacén',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showReceiveProductDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar Recepción'),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestión de Despacho de Mercancía',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registre la salida de productos del almacén',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showDispatchProductDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar Despacho'),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Disponible':
        color = AppTheme.successColor;
        break;
      case 'Bajo stock':
        color = AppTheme.warningColor;
        break;
      case 'Sin stock':
        color = AppTheme.errorColor;
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

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Producto'),
          content: const SingleChildScrollView(
            child: Text('Formulario para añadir producto (en desarrollo)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showReceiveProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Recepción'),
          content: const SingleChildScrollView(
            child: Text('Formulario para registrar recepción (en desarrollo)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showDispatchProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Despacho'),
          content: const SingleChildScrollView(
            child: Text('Formulario para registrar despacho (en desarrollo)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

