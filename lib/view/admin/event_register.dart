import 'package:flutter/material.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';
import 'package:larpland/util/error_message.dart';

class AddEventScreen extends StatefulWidget {
  final RoleplayEvent? event;

  const AddEventScreen({super.key, this.event});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController fechaInicioController = TextEditingController();
  final TextEditingController fechaFinController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      nameController.text = widget.event!.name;
      descriptionController.text = widget.event!.description;
      _fechaInicio = DateTime.tryParse(widget.event!.fechaInicio);
      _fechaFin = DateTime.tryParse(widget.event!.fechaFin);
      if (_fechaInicio != null) {
        fechaInicioController.text = _formatDateTime(_fechaInicio!);
      }
      if (_fechaFin != null) {
        fechaFinController.text = _formatDateTime(_fechaFin!);
      }
    }
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_fechaInicio ?? now)
        : (_fechaFin ?? _fechaInicio ?? now.add(const Duration(hours: 1)));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) {
      return;
    }

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _fechaInicio = selected;
        fechaInicioController.text = _formatDateTime(selected);
        if (_fechaFin != null && _fechaFin!.isBefore(selected)) {
          _fechaFin = null;
          fechaFinController.clear();
        }
      } else {
        _fechaFin = selected;
        fechaFinController.text = _formatDateTime(selected);
      }
    });
  }

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  String _toApiDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:00';
  }

  Future<void> _validateAndSubmit() async {
    if (!_validateAndSave()) {
      return;
    }

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha de inicio y fin.')),
      );
      return;
    }

    if (!_fechaFin!.isAfter(_fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de fin debe ser posterior al inicio.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditMode) {
        await updateEvent(
          widget.event!.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          fechaInicio: _toApiDateTime(_fechaInicio!),
          fechaFin: _toApiDateTime(_fechaFin!),
        );
      } else {
        await addEvent(
          nameController.text.trim(),
          descriptionController.text.trim(),
          _toApiDateTime(_fechaInicio!),
          _toApiDateTime(_fechaFin!),
        );
      }

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isEditMode ? 'Evento actualizado' : 'Evento agregado'),
          content: Text(
            _isEditMode
                ? 'El evento ha sido actualizado exitosamente.'
                : 'El evento ha sido agregado exitosamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            _isEditMode
                ? 'No se pudo actualizar el evento: ${uiErrorMessage(e)}'
                : 'No se pudo guardar el evento: ${uiErrorMessage(e)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF3EBD4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C4432), Color(0xFF8C3C2F), Color(0xFFD3BE8A)],
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
                                  _isEditMode ? 'Editar evento' : 'Agregar evento',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C4432),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Completa los datos del evento y define su rango de fechas.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: nameController,
                            decoration: _inputDecoration(
                              'Nombre del evento',
                              Icons.event_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese un nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: _inputDecoration(
                              'Descripcion',
                              Icons.description_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingrese una descripcion';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: fechaInicioController,
                            readOnly: true,
                            onTap: () => _pickDateTime(isStart: true),
                            decoration: _inputDecoration(
                              'Fecha y hora de inicio',
                              Icons.schedule,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: () => _pickDateTime(isStart: true),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona fecha de inicio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: fechaFinController,
                            readOnly: true,
                            onTap: () => _pickDateTime(isStart: false),
                            decoration: _inputDecoration(
                              'Fecha y hora de fin',
                              Icons.event_available_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: () => _pickDateTime(isStart: false),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona fecha de fin';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _validateAndSubmit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isEditMode
                                        ? Icons.save_outlined
                                        : Icons.add_task_outlined,
                                  ),
                            label: Text(
                              _isSubmitting
                                  ? 'Guardando...'
                                  : (_isEditMode
                                      ? 'Actualizar evento'
                                      : 'Guardar evento'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C4432),
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

