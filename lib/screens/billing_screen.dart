import 'package:flutter/material.dart';
import '../theme.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _filterValue = 'Todos';
  final List<String> _filterOptions = ['Todos', 'Pagadas', 'Pendientes', 'Vencidas'];

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
        title: const Text('Facturación'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Facturas'),
            Tab(text: 'Pagos'),
            Tab(text: 'Cotizaciones'),
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
                hintText: 'Buscar por número, cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Filtro: $_filterValue',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _showFilterDialog();
                  },
                  child: const Text('Cambiar'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción según la pestaña activa
                    switch (_tabController.index) {
                      case 0:
                        _showCreateInvoiceDialog();
                        break;
                      case 1:
                        _showRegisterPaymentDialog();
                        break;
                      case 2:
                        _showCreateQuoteDialog();
                        break;
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(_tabController.index == 0
                      ? 'Nueva Factura'
                      : _tabController.index == 1
                          ? 'Registrar Pago'
                          : 'Nueva Cotización'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesTab(),
                _buildPaymentsTab(),
                _buildQuotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    // Datos de ejemplo para las facturas
    final invoices = [
      {
        'id': '1',
        'number': 'FACT-001',
        'customer': 'Juan Pérez',
        'date': '2025-03-14',
        'amount': '\$350.00',
        'status': 'Pagada',
      },
      {
        'id': '2',
        'number': 'FACT-002',
        'customer': 'María González',
        'date': '2025-03-13',
        'amount': '\$520.75',
        'status': 'Pendiente',
      },
      {
        'id': '3',
        'number': 'FACT-003',
        'customer': 'Carlos Rodríguez',
        'date': '2025-03-10',
        'amount': '\$180.30',
        'status': 'Vencida',
      },
      {
        'id': '4',
        'number': 'FACT-004',
        'customer': 'Ana Martínez',
        'date': '2025-03-08',
        'amount': '\$420.50',
        'status': 'Pagada',
      },
      {
        'id': '5',
        'number': 'FACT-005',
        'customer': 'Roberto Sánchez',
        'date': '2025-03-05',
        'amount': '\$290.25',
        'status': 'Pendiente',
      },
    ];

    // Filtrar por búsqueda y estado
    final searchQuery = _searchController.text.toLowerCase();
    final filteredInvoices = invoices.where((invoice) {
      final matchesSearch = invoice['number']!.toLowerCase().contains(searchQuery) ||
          invoice['customer']!.toLowerCase().contains(searchQuery);
      
      final matchesFilter = _filterValue == 'Todos' || invoice['status'] == _filterValue;
      
      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredInvoices.isEmpty) {
      return const Center(
        child: Text('No se encontraron facturas'),
      );
    }

    return ListView.builder(
      itemCount: filteredInvoices.length,
      itemBuilder: (context, index) {
        final invoice = filteredInvoices[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              '${invoice['number']} - ${invoice['customer']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Fecha: ${invoice['date']} | Monto: ${invoice['amount']}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBadge(invoice['status']!),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () {
                    // Ver detalles de la factura
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.print_outlined),
                  onPressed: () {
                    // Imprimir factura
                  },
                ),
              ],
            ),
            onTap: () {
              // Ver detalles de la factura
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    // Implementación similar a la pestaña de facturas
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestión de Pagos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registre y consulte los pagos realizados por los clientes',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showRegisterPaymentDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar Pago'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesTab() {
    // Implementación similar a la pestaña de facturas
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestión de Cotizaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cree y gestione cotizaciones para sus clientes',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateQuoteDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva Cotización'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Pagada':
        color = AppTheme.successColor;
        break;
      case 'Pendiente':
        color = AppTheme.warningColor;
        break;
      case 'Vencida':
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar facturas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _filterOptions.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _filterValue,
                onChanged: (value) {
                  setState(() {
                    _filterValue = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Factura'),
          content: const SingleChildScrollView(
            child: Text('Formulario para crear factura (en desarrollo)'),
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

  void _showRegisterPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Pago'),
          content: const SingleChildScrollView(
            child: Text('Formulario para registrar pago (en desarrollo)'),
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

  void _showCreateQuoteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Cotización'),
          content: const SingleChildScrollView(
            child: Text('Formulario para crear cotización (en desarrollo)'),
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

