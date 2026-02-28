import 'package:flutter/material.dart';
import 'package:larpland/component/event_card.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';
import 'package:larpland/util/error_message.dart';
import 'package:larpland/view/admin/event_register.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

enum _EventStatusFilter { all, ongoing, upcoming, past }
enum _EventDateFilter { all, today, next7Days, next30Days }

class _EventScreenState extends State<EventScreen> {
  static const int _pageSize = 10;
  late Future<List<RoleplayEvent>> eventList;
  final TextEditingController _searchController = TextEditingController();
  _EventStatusFilter _statusFilter = _EventStatusFilter.all;
  _EventDateFilter _dateFilter = _EventDateFilter.all;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    eventList = fetchEventList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = fetchEventList();
    setState(() {
      eventList = future;
      _visibleCount = _pageSize;
    });
    await future;
  }

  void _resetPagination() {
    _visibleCount = _pageSize;
  }

  void _loadMore(int total) {
    if (_visibleCount >= total) {
      return;
    }
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
    });
  }

  String _statusLabel(_EventStatusFilter value) {
    return switch (value) {
      _EventStatusFilter.all => 'Todos',
      _EventStatusFilter.ongoing => 'En curso',
      _EventStatusFilter.upcoming => 'Proximos',
      _EventStatusFilter.past => 'Finalizados',
    };
  }

  String _dateLabel(_EventDateFilter value) {
    return switch (value) {
      _EventDateFilter.all => 'Todo',
      _EventDateFilter.today => 'Hoy',
      _EventDateFilter.next7Days => 'Prox. 7 dias',
      _EventDateFilter.next30Days => 'Prox. 30 dias',
    };
  }

  DateTime? _parseDate(String value) {
    return DateTime.tryParse(value)?.toLocal();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _matchesStatus(RoleplayEvent event, DateTime now) {
    final start = _parseDate(event.fechaInicio);
    final end = _parseDate(event.fechaFin) ?? start;
    if (start == null) {
      return _statusFilter == _EventStatusFilter.all;
    }

    return switch (_statusFilter) {
      _EventStatusFilter.all => true,
      _EventStatusFilter.upcoming => start.isAfter(now),
      _EventStatusFilter.ongoing =>
        !start.isAfter(now) && (end == null || !end.isBefore(now)),
      _EventStatusFilter.past => end?.isBefore(now) ?? start.isBefore(now),
    };
  }

  bool _matchesDate(RoleplayEvent event, DateTime now) {
    if (_dateFilter == _EventDateFilter.all) {
      return true;
    }

    final start = _parseDate(event.fechaInicio);
    if (start == null) {
      return false;
    }

    return switch (_dateFilter) {
      _EventDateFilter.all => true,
      _EventDateFilter.today => _isSameDay(start, now),
      _EventDateFilter.next7Days => !start.isBefore(now) &&
          start.difference(now) <= const Duration(days: 7),
      _EventDateFilter.next30Days => !start.isBefore(now) &&
          start.difference(now) <= const Duration(days: 30),
    };
  }

  List<RoleplayEvent> _applyFilters(List<RoleplayEvent> events) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    return events.where((event) {
      final matchesQuery = query.isEmpty
          ? true
          : event.name.toLowerCase().contains(query) ||
              event.description.toLowerCase().contains(query) ||
              '${event.id}'.contains(query);
      return matchesQuery && _matchesStatus(event, now) && _matchesDate(event, now);
    }).toList(growable: false);
  }

  Future<void> _openEventForm({RoleplayEvent? event}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEventScreen(event: event)),
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _deleteEvent(RoleplayEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar evento'),
        content: Text('Seguro que quieres borrar "${event.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await deleteEvent(event.id);
      if (!mounted) {
        return;
      }
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento borrado correctamente')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el evento: ${uiErrorMessage(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<RoleplayEvent>>(
          future: eventList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: uiErrorMessage(snapshot.error!),
                onRetry: _refresh,
              );
            }

            final filteredEvents = _applyFilters(snapshot.data ?? const <RoleplayEvent>[]);
            final hasFilters = _searchController.text.trim().isNotEmpty ||
                _statusFilter != _EventStatusFilter.all ||
                _dateFilter != _EventDateFilter.all;
            final visibleEnd = _visibleCount.clamp(0, filteredEvents.length);
            final visibleEvents = filteredEvents.take(visibleEnd).toList(growable: false);
            final canLoadMore = _visibleCount < filteredEvents.length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() => _resetPagination()),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, descripcion o ID...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _resetPagination());
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recargar',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFFFFAF0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<_EventStatusFilter>(
                              initialValue: _statusFilter,
                              isExpanded: true,
                              decoration: _filterDecoration('Estado'),
                              items: _EventStatusFilter.values
                                  .map(
                                    (value) => DropdownMenuItem<_EventStatusFilter>(
                                      value: value,
                                      child: Text(_statusLabel(value)),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _statusFilter = value;
                                  _resetPagination();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<_EventDateFilter>(
                              initialValue: _dateFilter,
                              isExpanded: true,
                              decoration: _filterDecoration('Fecha'),
                              items: _EventDateFilter.values
                                  .map(
                                    (value) => DropdownMenuItem<_EventDateFilter>(
                                      value: value,
                                      child: Text(_dateLabel(value)),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _dateFilter = value;
                                  _resetPagination();
                                });
                              },
                            ),
                          ),
                          if (hasFilters) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _statusFilter = _EventStatusFilter.all;
                                  _dateFilter = _EventDateFilter.all;
                                  _resetPagination();
                                });
                              },
                              child: const Text('Limpiar'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredEvents.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            _EmptyState(
                              icon: hasFilters
                                  ? Icons.search_off_outlined
                                  : Icons.event_busy_outlined,
                              message: hasFilters
                                  ? 'No hay eventos con esos filtros'
                                  : 'Sin eventos',
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                            itemCount: visibleEvents.length + (canLoadMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (canLoadMore && index == visibleEvents.length) {
                                return _LoadMoreListTile(
                                  remaining: filteredEvents.length - visibleEvents.length,
                                  onPressed: () => _loadMore(filteredEvents.length),
                                );
                              }

                              final event = visibleEvents[index];
                              return EventCard(
                                event: event,
                                margin: const EdgeInsets.only(bottom: 10),
                                trailingAction: Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _openEventForm(event: event),
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Editar'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _deleteEvent(event),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Borrar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _openEventForm,
            backgroundColor: const Color(0xFF2C4432),
            foregroundColor: Colors.white,
            tooltip: 'Agregar evento',
            heroTag: 'add_event',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _LoadMoreListTile extends StatelessWidget {
  final int remaining;
  final VoidCallback onPressed;

  const _LoadMoreListTile({
    required this.remaining,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
      ),
      child: ListTile(
        onTap: onPressed,
        leading: const Icon(Icons.expand_more_rounded, color: Color(0xFF2C4432)),
        title: const Text(
          'Cargar mas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$remaining evento(s) restantes'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF8C3C2F)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF2C4432),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: Color(0xFF2C4432),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
