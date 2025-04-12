import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/image_service.dart';
import '../services/web_safe_image.dart';
import '../theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class AddProductScreen extends StatefulWidget {
  final Function(Product) onProductAdded;
  
  const AddProductScreen({Key? key, required this.onProductAdded}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _pesoController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _linkController = TextEditingController();
  final ProductService _productService = ProductService();
  final CloudinaryService _imageService = CloudinaryService(); 
 
 // Update to CloudinaryService
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;
  
  File? _productImage;
  File? _invoiceImage;
  final _picker = ImagePicker();
  
   @override
  void initState() {
    super.initState();
    
    // Check auth on init
    _checkAuthentication();
  }
   Widget _buildImagePreview(File? imageFile, String? imageUrl) {
    if (kIsWeb) {
      if (imageFile != null) {
        // Use URL.createObjectURL for web
        return Image.network(
          imageFile.path,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else {
      if (imageFile != null) {
        return Image.file(
          imageFile,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
     if (imageUrl != null) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return const SizedBox.shrink();
  }
 // Update image picker method
  Future<void> _checkAuthentication() async {
    final userId = await _storage.read(key: 'userId');
    final token = await _storage.read(key: 'token');
    
    print('Initial auth check:');
    print('User ID: $userId');
    print('Token exists: ${token != null}');
    
    if (userId == null || token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión inválida. Redirigiendo al login...'))
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
Future<void> _pickProductImage() async {
  try {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _productImage = File(pickedFile.path);
        });
      } else {
        setState(() {
          _productImage = File(pickedFile.path);
        });
      }
    }
  } catch (e) {
    print('Error picking image: $e');
    setState(() {
      _errorMessage = 'Error al cargar la imagen: $e';
    });
  }
}

// Replace Image.file with WebSafeImage


  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _pesoController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  

  Future<void> _pickInvoiceImage() async {
  try {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _invoiceImage = File(pickedFile.path);
        });
      } else {
        setState(() {
          _invoiceImage = File(pickedFile.path);
        });
      }
    }
  } catch (e) {
    print('Error picking invoice image: $e');
    setState(() {
      _errorMessage = 'Error al cargar la factura: $e';
    });
  }
}
Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use correct key 'userId' instead of 'id'
      final userId = await _storage.read(key: 'userId');
      final token = await _storage.read(key: 'token');
      
      print('Auth check:');
      print('User ID from storage: $userId');
      print('Token present: ${token != null}');
      print('Token length: ${token?.length ?? 0}');

      if (userId == null || token == null) {
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
      }

      // Validate and parse values
      double precio = double.parse(_precioController.text.trim());
      double peso = double.parse(_pesoController.text.trim());
      int cantidad = int.parse(_cantidadController.text.trim());

      print('Valores a enviar:');
      print('User ID: $userId');
      print('Precio: $precio');
      print('Peso: $peso');
      print('Cantidad: $cantidad');

      // Upload images with error logging
      String? imagenUrl;
      String? facturaUrl;

      try {
        if (_productImage != null) {
          imagenUrl = await CloudinaryService.uploadImage(_productImage!);
          print('Imagen producto subida: $imagenUrl');
        }

        if (_invoiceImage != null) {
          facturaUrl = await CloudinaryService.uploadImage(_invoiceImage!);
          print('Imagen factura subida: $facturaUrl');
        }
      } catch (e) {
        print('Error subiendo imágenes: $e');
        throw Exception('Error al subir las imágenes: ${e.toString()}');
      }

      try {
        // Create product with the correct userId
        final newProduct = Product(
          id: '',  // Empty for new product
          id_user: userId, // Use correct userId from storage
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          peso: peso,
          precio: precio,
          cantidad: cantidad,
          link: _linkController.text.isNotEmpty ? _linkController.text : null,
          imagenUrl: imagenUrl,
          facturaUrl: facturaUrl,
          fechaCreacion: DateTime.now(),
        );

        print('Enviando producto al servidor...');
        print('Product datos - userId: ${newProduct.id_user}, nombre: ${newProduct.nombre}');
        
        final addedProduct = await _productService.addProduct(newProduct);
        print('Respuesta del servidor: ${addedProduct.id}');
        
        if (mounted) {
          widget.onProductAdded(addedProduct);
          await _showSuccessDialog();
        }
      } catch (e) {
        print('Error en la petición HTTP: $e');
        if (e.toString().contains('403') || e.toString().contains('401')) {
          // Attempt to refresh token if implemented
          throw Exception('No tienes permiso para realizar esta acción. Por favor inicia sesión nuevamente.');
        }
        throw Exception('Error al guardar el producto: ${e.toString()}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error final: $_errorMessage');
    }
  }
}
// Update TextFormField validator
String _formatNumber(String value) {
  if (value.isEmpty) return '';
  
  // Remove non-digit characters except decimal point
  value = value.replaceAll(RegExp(r'[^\d.]'), '');
  
  try {
    // Parse and format to ensure valid number
    final number = double.parse(value);
    return number.toString();
  } catch (e) {
    return '';
  }
}
Future<void> _showSuccessDialog() async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 28),
          const SizedBox(width: 8),
          const Text('¡Producto Registrado!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El producto "${_nombreController.text}" ha sido registrado exitosamente.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ahora puedes incluirlo en tus envíos.',
            style: TextStyle(color: AppTheme.mutedTextColor),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Return to previous screen
          },
          child: const Text('VOLVER A PRODUCTOS'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _formKey.currentState!.reset();
            _nombreController.clear();
            _descripcionController.clear();
            _pesoController.clear();
            _precioController.clear();
            _cantidadController.clear();
            _linkController.clear();
            setState(() {
              _productImage = null;
              _invoiceImage = null;
              _currentStep = 0;
              _isLoading = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('AGREGAR OTRO'),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo Producto'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
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
              } else {
                Navigator.pop(context);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading && _currentStep == 3
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_currentStep < 2 ? 'CONTINUAR' : 'GUARDAR PRODUCTO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(_currentStep > 0 ? 'ATRÁS' : 'CANCELAR'),
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Información Básica'),
                subtitle: const Text('Nombre y descripción del producto'),
                content: Column(
                  children: [
                    if (_errorMessage != null && _currentStep == 0)
                      _buildErrorMessage(),
                    
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del producto',
                        hintText: 'Ej: Smartphone XYZ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.inventory),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre del producto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Describe las características del producto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: 'Link (opcional)',
                        hintText: 'URL del producto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.link),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Especificaciones'),
                subtitle: const Text('Peso y cantidad'),
                content: Column(
                  children: [
                    if (_errorMessage != null && _currentStep == 1)
                      _buildErrorMessage(),
                    
                    // Update numeric field validation
// Add helper methods


// Update TextFormField for price
TextFormField(
  controller: _precioController,
  decoration: InputDecoration(
    labelText: 'Precio',
    hintText: 'Ej: 99.99',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    prefixIcon: const Icon(Icons.attach_money),
    filled: true,
    fillColor: Colors.white,
  ),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  onChanged: (value) {
    final formattedValue = _formatNumber(value);
    if (formattedValue != value) {
      _precioController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el precio';
    }
    try {
      final price = double.tryParse(value);
      if (price == null || price <= 0) {
        return 'El precio debe ser mayor a 0';
      }
    } catch (e) {
      return 'Ingresa un número válido';
    }
    return null;
  },
),
TextFormField(
        controller: _cantidadController,
        decoration: InputDecoration(
          labelText: 'Cantidad',
          hintText: 'Ej: 1',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.inventory),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa la cantidad';
          }
          try {
            final cantidadNum = int.parse(value);
            if (cantidadNum <= 0) {
              return 'La cantidad debe ser mayor a 0';
            }
          } catch (e) {
            return 'Ingresa un número válido';
          }
          return null;
        },
      ),
// Update TextFormField for weight
TextFormField(
  controller: _pesoController,
  decoration: InputDecoration(
    labelText: 'Peso (kg)',
    hintText: 'Ej: 0.5',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    prefixIcon: const Icon(Icons.scale),
    suffixText: 'kg',
    filled: true,
    fillColor: Colors.white,
  ),
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  onChanged: (value) {
    final formattedValue = _formatNumber(value);
    if (formattedValue != value) {
      _pesoController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el peso';
    }
    try {
      final weight = double.tryParse(value);
      if (weight == null || weight <= 0) {
        return 'El peso debe ser mayor a 0';
      }
    } catch (e) {
      return 'Ingresa un número válido';
    }
    return null;
  },
),
                    const SizedBox(height: 16),
                    
                    // Información sobre envíos
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Información de Envío',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'El peso del producto afecta directamente el costo de envío. Asegúrate de proporcionar un peso preciso para evitar cargos adicionales.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
  title: const Text('Imágenes'),
  subtitle: const Text('Fotos del producto y factura'),
  content: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_errorMessage != null && _currentStep == 2)
        _buildErrorMessage(),
      const Text(
        'Imagen del Producto',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Sube una foto clara del producto para que podamos identificarlo fácilmente.',
        style: TextStyle(
          color: AppTheme.mutedTextColor,
        ),
      ),
      const SizedBox(height: 16),
      // Selector de imagen del producto
      GestureDetector(
        onTap: _pickProductImage,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _productImage != null
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
            ),
          ),
          child: _productImage != null
              ? // Replace Image.file section with:
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Stack(
    children: [
      WebSafeImage(
        imageFile: _productImage,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
            onPressed: _pickProductImage,
            tooltip: 'Cambiar imagen',
          ),
        ),
      ),
    ],
  ),
)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toca para agregar una foto',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Imagen de la Factura (opcional)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Sube una foto de la factura para facilitar el proceso de envío y seguimiento.',
        style: TextStyle(
          color: AppTheme.mutedTextColor,
        ),
      ),
      const SizedBox(height: 16),
      // Selector de imagen de la factura
      GestureDetector(
        onTap: _pickInvoiceImage,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _invoiceImage != null
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
            ),
          ),
          child: _invoiceImage != null
              ? ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Stack(
    children: [
      WebSafeImage(
        imageFile: _invoiceImage,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
            onPressed: _pickInvoiceImage,
            tooltip: 'Cambiar factura',
          ),
        ),
      ),
    ],
  ),
)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toca para agregar la factura',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 16),
      // Información sobre imágenes
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Importante',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Las imágenes ayudan a identificar tu producto durante el proceso de envío. Una imagen clara de la factura puede agilizar trámites aduaneros para envíos internacionales.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  ),
  isActive: _currentStep >= 2,
  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.mutedTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

