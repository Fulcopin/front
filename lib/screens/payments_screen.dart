import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  bool _paymentSuccess = false;
  
  // Controladores para el formulario
  final _montoController = TextEditingController();
  String _metodoPago = 'tarjeta';

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _realizarPago() async {
    // Validar el formulario
    if (_montoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un monto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simular procesamiento de pago
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _paymentSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Realizar Pago'),
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
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Mis Productos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card_outlined),
              title: const Text('Realizar Pago'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Mis Envíos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/my-shipments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/profile');
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
      body: _paymentSuccess
          ? _buildPaymentSuccess()
          : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Pago',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa los detalles para realizar tu pago',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        TextField(
          controller: _montoController,
          decoration: InputDecoration(
            labelText: 'Monto a pagar',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.attach_money),
            prefixText: '\$',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
                  const SizedBox(height: 16),
                  const Text(
                    'Método de pago',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Tarjeta de Crédito/Débito'),
                    value: 'tarjeta',
                    groupValue: _metodoPago,
                    onChanged: (value) {
                      setState(() {
                        _metodoPago = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('PayPal'),
                    value: 'paypal',
                    groupValue: _metodoPago,
                    onChanged: (value) {
                      setState(() {
                        _metodoPago = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Transferencia Bancaria'),
                    value: 'transferencia',
                    groupValue: _metodoPago,
                    onChanged: (value) {
                      setState(() {
                        _metodoPago = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_metodoPago == 'tarjeta') ...[
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Número de tarjeta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: const TextField(
                            decoration: InputDecoration(
                              labelText: 'Fecha de expiración',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: const TextField(
                            decoration: InputDecoration(
                              labelText: 'CVC',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Nombre en la tarjeta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_metodoPago == 'paypal') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Serás redirigido a PayPal para completar el pago',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('Continuar con PayPal'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_metodoPago == 'transferencia') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Datos bancarios:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Banco: Banco Nacional'),
                          Text('Cuenta: 1234-5678-9012-3456'),
                          Text('Titular: Vacabox Courier S.A.'),
                          Text('Referencia: Tu ID de cliente'),
                          SizedBox(height: 8),
                          Text(
                            'Una vez realizada la transferencia, envía el comprobante a pagos@vacabox.com',
                            style: TextStyle(
                              color: AppTheme.mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _realizarPago,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Realizar Pago'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('\$${_montoController.text.isEmpty ? "0.00" : double.parse(_montoController.text).toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Impuestos (16%)'),
                      Text('\$${_montoController.text.isEmpty ? "0.00" : (double.parse(_montoController.text) * 0.16).toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${_montoController.text.isEmpty ? "0.00" : (double.parse(_montoController.text) * 1.16).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Pago realizado con éxito!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu pago ha sido procesado correctamente',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/my-shipments');
            },
            child: const Text('Ir a Mis Envíos'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 44),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentSuccess = false;
                _montoController.clear();
              });
            },
            child: const Text('Realizar otro pago'),
          ),
        ],
      ),
    );
  }
}

