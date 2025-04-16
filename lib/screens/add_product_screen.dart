import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/image_service.dart';
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
  
  // Updated controllers to match the new design
  final _tiendaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _trackingController = TextEditingController();
  final _precioController = TextEditingController();
  final _pesoController = 0;
  
  final ProductService _productService = ProductService();
  final CloudinaryService _imageService = CloudinaryService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  File? _facturaImage;
  final _picker = ImagePicker();
  
  // Default image URL to use if no image is provided
  final String _defaultImageUrl = 'https://media.istockphoto.com/id/1186665850/es/vector/cami%C3%B3n-de-entrega-de-env%C3%ADo-r%C3%A1pido-dise%C3%B1o-de-icono-de-l%C3%ADnea-ilustraci%C3%B3n-vectorial-para.jpg?s=612x612&w=0&k=20&c=4IODuEWsnMLEgriQF7rOu3mN3CXtXVmQPVgJngit0jE=';
  
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }
  
  @override
  void dispose() {
    _tiendaController.dispose();
    _descripcionController.dispose();
    _trackingController.dispose();
    _precioController.dispose();

    super.dispose();
  }
  
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
  
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _facturaImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = 'Error al cargar la imagen: $e';
      });
    }
  }
  
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
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userId = await _storage.read(key: 'userId');
        final token = await _storage.read(key: 'token');
        
        if (userId == null || token == null) {
          throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
        }

        // Validate and parse values
        double precio = double.parse(_precioController.text.trim());
        double peso = 0;
        // Use 1 as default quantity since we don't have a field for it
        int cantidad = 1;

        // Upload image if available
        String? facturaUrl;
        try {
          if (_facturaImage != null) {
            facturaUrl = await CloudinaryService.uploadImage(_facturaImage!);
            print('Imagen factura subida: $facturaUrl');
          }
        } catch (e) {
          print('Error subiendo imagen: $e');
          // Continue with default image if upload fails
        }

        // Create product with the user input
        final newProduct = Product(
          id: '',  // Empty for new product
          id_user: userId,
          nombre: _tiendaController.text,
          descripcion: _descripcionController.text,
          peso: peso,
          precio: precio,
          cantidad: cantidad,
          link: _trackingController.text,
          // Use default image if no image was uploaded
          imagenUrl: _defaultImageUrl,
          facturaUrl: facturaUrl,
          fechaCreacion: DateTime.now(),
        );

        print('Enviando producto al servidor...');
        final addedProduct = await _productService.addProduct(newProduct);
        print('Producto guardado con ID: ${addedProduct.id}');
        
        if (mounted) {
          widget.onProductAdded(addedProduct);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto registrado exitosamente'))
          );
          
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
        print('Error final: $_errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerta Bodega'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.red.shade100,
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  TextFormField(
                    controller: _tiendaController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Tienda',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el nombre de la tienda';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción del producto :9 perfumes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una descripción';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _trackingController,
                    decoration: InputDecoration(
                      labelText: 'Tracking de la Tienda',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el código de tracking';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                                TextFormField(
                  controller: _precioController,
                  decoration: InputDecoration(
                    labelText: 'Precio del paquete',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    // Allow decimal input without reformatting while typing
                    if (value.isEmpty) return;
                    
                    // Only format if there's an invalid pattern
                    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(value)) {
                      final formattedValue = _formatNumber(value);
                      _precioController.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(offset: formattedValue.length),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el precio';
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
                SizedBox(height: 16),

                
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagen de la Factura:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Esta imagen es opcional. Si no se proporciona, se usará una imagen por defecto.',
                        style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _facturaImage != null 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _facturaImage != null
                              ? kIsWeb
                                  ? Image.network(_facturaImage!.path, fit: BoxFit.cover)
                                  : Image.file(_facturaImage!, fit: BoxFit.cover)
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Toca para agregar factura'),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Registrar Producto',
                          style: TextStyle(fontSize: 16),
                        ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}