import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
class USAShippingAddressScreen extends StatefulWidget {
  const USAShippingAddressScreen({Key? key}) : super(key: key);

  @override
  State<USAShippingAddressScreen> createState() => _USAShippingAddressScreenState();
}

class _USAShippingAddressScreenState extends State<USAShippingAddressScreen> {
  final Map<String, String> _shippingData = {
    'Nombre usuario': 'VACABOX',
    'Dirección': '6951 NW 82nd Ave',
    'Ciudad/Estado': 'Miami, Florida',
    'Código postal': '33195-2881 United States',
    'Celular': '9549143306',
  };

  Map<String, bool> _copiedStatus = {};

  @override
  void initState() {
    super.initState();
    // Inicializar el estado de copiado para cada campo
    for (var key in _shippingData.keys) {
      _copiedStatus[key] = false;
    }
     _loadUserData();
  }
 Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('name') ?? '';
      
      if (userName.isNotEmpty) {
        setState(() {
          _shippingData['Nombre usuario'] = '$userName / VACABOX';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  void _copyToClipboard(String key, String value) {
    Clipboard.setData(ClipboardData(text: value));
    
    // Actualizar el estado para mostrar la confirmación
    setState(() {
      _copiedStatus[key] = true;
    });
    
    // Mostrar snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$key copiado al portapapeles'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Restablecer el estado después de un tiempo
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStatus[key] = false;
        });
      }
    });
  }

  void _copyAllToClipboard() {
    final allData = _shippingData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    Clipboard.setData(ClipboardData(text: allData));
    
    // Mostrar snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todos los datos copiados al portapapeles'),
        backgroundColor: AppTheme.successColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dirección de Envío en USA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copiar todo',
            onPressed: _copyAllToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: () {
              // Implementar compartir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de compartir en desarrollo'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildInstructions(),
              const SizedBox(height: 24),
              _buildFAQSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Datos de Envío a USA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Image.asset(
                  'assets/images/usa_flag.png',
                  width: 40,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.flag,
                      color: AppTheme.primaryColor,
                      size: 24,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa estos datos para tus compras en tiendas de USA',
              style: TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 14,
              ),
            ),
            const Divider(height: 24),
            ..._shippingData.entries.map((entry) => _buildDataRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    final isCopied = _copiedStatus[label] ?? false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isCopied ? Icons.check_circle : Icons.copy,
              color: isCopied ? AppTheme.successColor : AppTheme.primaryColor,
            ),
            tooltip: isCopied ? 'Copiado' : 'Copiar',
            onPressed: () => _copyToClipboard(label, value),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instrucciones de Uso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              '1',
              'Copia los datos de envío',
              'Usa los botones de copia para cada campo o copia todo con el botón en la barra superior.',
              Icons.copy,
            ),
            _buildInstructionStep(
              '2',
              'Realiza tu compra en la tienda online',
              'Pega los datos en el formulario de envío de la tienda donde estás comprando.',
              Icons.shopping_cart,
            ),
            _buildInstructionStep(
              '3',
              'Notifícanos de tu compra',
              'Una vez realizada la compra, notifícanos para estar atentos a la llegada de tu paquete.',
              Icons.notification_important,
            ),
            _buildInstructionStep(
              '4',
              'Recibe tu paquete',
              'Te notificaremos cuando tu paquete llegue a nuestra bodega y esté listo para enviarse a tu país.',
              Icons.inventory_2,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description, IconData icon, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(top: 4, right: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.mutedTextColor,
                  fontSize: 14,
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    return ExpansionTile(
      title: const Text(
        'Preguntas Frecuentes',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        _buildFAQItem(
          '¿Cuánto tiempo tarda en llegar mi paquete a la bodega de VACABOX?',
          'El tiempo depende del vendedor y el método de envío que elijas. Normalmente toma entre 3-7 días hábiles para envíos estándar dentro de USA.',
        ),
        _buildFAQItem(
          '¿Cómo sabré cuando mi paquete llegue a la bodega?',
          'Te enviaremos una notificación por correo electrónico y en la app cuando tu paquete llegue a nuestra bodega en Miami.',
        ),
        _buildFAQItem(
          '¿Qué pasa si la tienda no acepta mi dirección de envío?',
          'Algunas tiendas pueden tener restricciones para envíos a casilleros. En ese caso, contáctanos para buscar una solución alternativa.',
        ),
        _buildFAQItem(
          '¿Puedo enviar varios paquetes a la misma dirección?',
          'Sí, puedes enviar tantos paquetes como desees a esta dirección. Solo asegúrate de incluir tu nombre de usuario VACABOX en cada envío.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedTextColor,
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
