import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
class AdminProductsTable extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final Function(Product)? onViewProduct;
  final Function(Product, String?)? onEditProduct;
  final Function(Product)? onDeleteProduct;
  final Function(Product)? onNotifyUser;
  final Function()? onDataUpdated; 
  const AdminProductsTable({
    Key? key,
    required this.products,
    this.isLoading = false,
    this.onViewProduct,
    this.onEditProduct,
    this.onDeleteProduct,
    this.onNotifyUser,
     this.onDataUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos de Usuarios',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    // Ver todos los productos
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver Todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Precio')),
                  DataColumn(label: Text('Peso')),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: products.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            if (product.imagenUrl != null)
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(product.imagenUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            Flexible(
                              child: Text(
                                product.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(product.usuario != null
                          ? '${product.usuario!['nombre'] ?? ''} ${product.usuario!['apellido'] ?? ''}'
                          : 'Sin usuario')),
                      DataCell(Text('\$${product.precio.toStringAsFixed(2)}')),
                      DataCell(Text('${product.peso} kg')),
                      DataCell(Text('${product.cantidad}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(product.estado ?? 'No llegado'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.estado ?? 'No llegado',
                            style: TextStyle(
                              color: _getStatusTextColor(product.estado ?? 'No llegado'),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              onPressed: () => onViewProduct?.call(product),
                              tooltip: 'Ver Detalles',
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showStatusChangeDialog(context, product),
                              tooltip: 'Cambiar Estado',
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => onDeleteProduct?.call(product),
                              tooltip: 'Eliminar',
                              color: Colors.red,
                              iconSize: 20,
                            ),
                            if (product.estado == 'En bodega')
                              IconButton(
                                icon: const Icon(Icons.notifications_active_outlined),
                                onPressed: () => onNotifyUser?.call(product),
                                tooltip: 'Notificar Usuario',
                                color: Colors.orange,
                                iconSize: 20,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... _buildLoadingState() permanece igual ...
void _showStatusChangeDialog(BuildContext context, Product product) {
  String? selectedStatus = product.estado;
  final ProductService productService = ProductService(); // Instancia directa para debugging

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Cambiar estado de ${product.nombre}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusRadio(
                  context,
                  value: 'No llegado',
                  currentStatus: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
                _buildStatusRadio(
                  context,
                  value: 'En bodega',
                  currentStatus: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
                _buildStatusRadio(
                  context,
                  value: 'Pagado',
                  currentStatus: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
  onPressed: () async {
    if (selectedStatus != null && selectedStatus != product.estado) {
      print("⭐ INTENTANDO ACTUALIZACIÓN: producto=${product.id}, estado=$selectedStatus");
      
      Navigator.pop(context);
      
      // 1. Llamar al callback normal
      if (onEditProduct != null) {
        print("➡️ Llamando a onEditProduct callback");
        onEditProduct?.call(product, selectedStatus);
      } else {
        print("⚠️ onEditProduct es null - no configurado");
      }
      
      // 2. Intento directo para debugging
      try {
        print("➡️ Intentando actualización directa para debugging");
        final result = await productService.updateProductStatus(
          product.id, 
          selectedStatus ?? 'En bodega'
        );
        print("✅ Resultado de actualización directa: $result");
         // Si la actualización fue exitosa, recargar datos
        if (result && onDataUpdated != null) {
          print("♻️ Recargando datos después de actualizar");
          onDataUpdated?.call();
        }
      } catch (e) {
        print("❌ Error en actualización directa: $e");
      }
    } else {
      Navigator.pop(context);
      print("ℹ️ No hay cambios en el estado");
    }
  },
  child: const Text('Guardar Cambios'),
),
            ],
          );
        },
      );
    },
  );
}

  Widget _buildStatusRadio(
    BuildContext context, {
    required String value,
    required String? currentStatus,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: value,
        groupValue: currentStatus,
        onChanged: onChanged,
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(value),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: _getStatusTextColor(value),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => onChanged(value),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'No llegado':
        return Colors.orange.withOpacity(0.2);
      case 'En bodega':
        return Colors.blue.withOpacity(0.2);
      case 'Pagado':
        return Colors.green.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'No llegado':
        return Colors.orange.shade800;
      case 'En bodega':
        return Colors.blue.shade800;
      case 'Pagado':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}