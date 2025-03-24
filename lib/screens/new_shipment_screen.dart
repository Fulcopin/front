import 'package:flutter/material.dart';
import '../theme.dart';

class NewShipmentScreen extends StatefulWidget {
  const NewShipmentScreen({Key? key}) : super(key: key);

  @override
  State<NewShipmentScreen> createState() => _NewShipmentScreenState();
}

class _NewShipmentScreenState extends State<NewShipmentScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos de formulario
  final _senderNameController = TextEditingController();
  final _senderEmailController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _senderAddressController = TextEditingController();
  
  final _recipientNameController = TextEditingController();
  final _recipientEmailController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _recipientAddressController = TextEditingController();
  
  final _packageWeightController = TextEditingController();
  final _packageLengthController = TextEditingController();
  final _packageWidthController = TextEditingController();
  final _packageHeightController = TextEditingController();
  final _packageValueController = TextEditingController();
  
  String _packageCategory = 'Electrónicos';
  final List<String> _packageCategories = [
    'Electrónicos',
    'Ropa',
    'Documentos',
    'Alimentos',
    'Medicamentos',
    'Otros',
  ];
  
  bool _isFragile = false;
  bool _requiresSignature = true;
  
  String _shippingMethod = 'Estándar';
  final List<String> _shippingMethods = [
    'Estándar',
    'Express',
    'Prioritario',
    'Económico',
  ];
  
  @override
  void dispose() {
    _senderNameController.dispose();
    _senderEmailController.dispose();
    _senderPhoneController.dispose();
    _senderAddressController.dispose();
    
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    _recipientPhoneController.dispose();
    _recipientAddressController.dispose();
    
    _packageWeightController.dispose();
    _packageLengthController.dispose();
    _packageWidthController.dispose();
    _packageHeightController.dispose();
    _packageValueController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Envío'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _submitForm();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep < 3 ? 'Continuar' : 'Finalizar'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Atrás'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Remitente'),
              content: _buildSenderForm(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Destinatario'),
              content: _buildRecipientForm(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Paquete'),
              content: _buildPackageForm(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Envío'),
              content: _buildShippingForm(),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _senderNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el nombre del remitente';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senderEmailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el correo electrónico';
            }
            // Validación básica de email
            if (!value.contains('@') || !value.contains('.')) {
              return 'Por favor ingrese un correo electrónico válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senderPhoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el teléfono';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senderAddressController,
          decoration: const InputDecoration(
            labelText: 'Dirección completa',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese la dirección';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRecipientForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _recipientNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el nombre del destinatario';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _recipientEmailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el correo electrónico';
            }
            // Validación básica de email
            if (!value.contains('@') || !value.contains('.')) {
              return 'Por favor ingrese un correo electrónico válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _recipientPhoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el teléfono';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _recipientAddressController,
          decoration: const InputDecoration(
            labelText: 'Dirección completa',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese la dirección';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPackageForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _packageCategory,
          decoration: const InputDecoration(
            labelText: 'Categoría del paquete',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _packageCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _packageCategory = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _packageWeightController,
          decoration: const InputDecoration(
            labelText: 'Peso (kg)',
            prefixIcon: Icon(Icons.scale_outlined),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el peso';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _packageLengthController,
                decoration: const InputDecoration(
                  labelText: 'Largo (cm)',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _packageWidthController,
                decoration: const InputDecoration(
                  labelText: 'Ancho (cm)',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _packageHeightController,
                decoration: const InputDecoration(
                  labelText: 'Alto (cm)',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _packageValueController,
          decoration: const InputDecoration(
            labelText: 'Valor declarado (USD)',
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _isFragile,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _isFragile = value!;
                });
              },
            ),
            const Text('Contenido frágil'),
          ],
        ),
      ],
    );
  }

  Widget _buildShippingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _shippingMethod,
          decoration: const InputDecoration(
            labelText: 'Método de envío',
            prefixIcon: Icon(Icons.local_shipping_outlined),
          ),
          items: _shippingMethods.map((method) {
            return DropdownMenuItem<String>(
              value: method,
              child: Text(method),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _shippingMethod = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _requiresSignature,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _requiresSignature = value!;
                });
              },
            ),
            const Text('Requiere firma en la entrega'),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del envío',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Costo de envío:'),
                    Text(
                      '\$45.00 USD',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Impuestos:'),
                    Text(
                      '\$5.00 USD',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Seguro:'),
                    Text(
                      '\$10.00 USD',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$60.00 USD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Aquí iría la lógica para enviar los datos al servidor
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Envío creado con éxito!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Navegar de vuelta al dashboard
      Navigator.pop(context);
    }
  }
}

