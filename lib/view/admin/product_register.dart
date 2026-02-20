import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  XFile? image;
  Uint8List? imageBytes;

  bool get isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      nameController.text = widget.product!.nombre;
      descriptionController.text = widget.product!.descripcion;
      priceController.text = widget.product!.precio;
      stockController.text = widget.product!.cantidad.toString();
      categoryController.text = widget.product!.categoria;
      image = null;
      imageBytes = null;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        image = pickedFile;
        imageBytes = null;
      });
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        imageBytes = bytes;
      });
    }
  }

  Future<void> _validateAndSubmit() async {
    if (!_validateAndSave()) return;

    try {
      if (!isEditMode) {
        if (image == null) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Imagen requerida'),
              content: const Text('Selecciona una imagen antes de guardar.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        await addProduct(
          nameController.text,
          descriptionController.text,
          priceController.text,
          int.parse(stockController.text),
          categoryController.text,
          image!,
        );

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Producto agregado'),
            content: const Text('El producto ha sido agregado exitosamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }

      await updateProduct(
        widget.product!.id,
        name: nameController.text,
        descripcion: descriptionController.text,
        precio: priceController.text,
        stock: int.parse(stockController.text),
        categoria: categoryController.text,
        imagen: image,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Producto actualizado'),
          content: const Text('El producto ha sido actualizado exitosamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D3557), Color(0xFF457B9D), Color(0xFFA8DADC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEditMode
                                      ? 'Actualizar producto'
                                      : 'Agregar producto',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D3557),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: nameController,
                            decoration:
                                _inputDecoration('Nombre', Icons.badge_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese el nombre del producto';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Descripcion',
                              Icons.description_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese la descripcion del producto';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration:
                                      _inputDecoration('Precio', Icons.attach_money),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el precio';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      _inputDecoration('Stock', Icons.inventory_2),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el stock';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: categoryController,
                            decoration: _inputDecoration(
                              'Categoria',
                              Icons.category_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese la categoria';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(
                              image == null
                                  ? 'Seleccionar imagen'
                                  : 'Cambiar imagen',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1D3557),
                              side: const BorderSide(
                                color: Color(0xFF1D3557),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isEditMode && imageBytes == null)
                            SmartNetworkImage(
                              imagePath: widget.product!.imagen,
                              height: 300,
                              width: 300,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          if (imageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                imageBytes!,
                                height: 300,
                                width: 300,
                                fit: BoxFit.contain,
                              ),
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _validateAndSubmit,
                            icon: Icon(
                              isEditMode ? Icons.save_outlined : Icons.add_box_outlined,
                            ),
                            label: Text(
                              isEditMode
                                  ? 'Actualizar producto'
                                  : 'Agregar producto',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D3557),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
