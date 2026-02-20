

import 'package:flutter/material.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {

  late Future<RoleplayEvent> futureEvent;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController fechaInicioController = TextEditingController();
  TextEditingController fechaFinController = TextEditingController();

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      try {
        futureEvent = addEvent(
          nameController.text,
          descriptionController.text,
          fechaInicioController.text,
          fechaFinController.text,
        );
        await futureEvent;
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Evento Agregado'),
            content: const Text('El evento ha sido agregado exitosamente'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error: $e'),
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
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    fechaInicioController.dispose();
    fechaFinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: fechaInicioController,
                decoration: const InputDecoration(labelText: 'Fecha de Inicio'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor ingrese una fecha de inicio';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: fechaFinController,
                decoration: const InputDecoration(labelText: 'Fecha de Fin'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor ingrese una fecha de fin';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _validateAndSubmit,
                child: const Text('Agregar Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
     
  
