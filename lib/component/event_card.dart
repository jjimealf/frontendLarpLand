import 'package:flutter/material.dart';
import 'package:larpland/model/roleplay_event.dart';

class EventCard extends StatelessWidget {
  final RoleplayEvent event;
  final Widget? trailingAction;
  final EdgeInsetsGeometry? margin;

  const EventCard({
    super.key,
    required this.event,
    this.trailingAction,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    const parchmentWhite = Color(0xFFFFFAF0);

    return Card(
      margin: margin,
      elevation: 0,
      color: parchmentWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBD4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_available_outlined,
                    color: Color(0xFF2C4432),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF2C4432),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ink.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DateChip(
                  label: 'Inicio',
                  value: _formatDateTime(event.fechaInicio),
                  icon: Icons.schedule_outlined,
                ),
                _DateChip(
                  label: 'Fin',
                  value: _formatDateTime(event.fechaFin),
                  icon: Icons.flag_outlined,
                ),
              ],
            ),
            if (trailingAction != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: trailingAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    final h = parsed.hour.toString().padLeft(2, '0');
    final min = parsed.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DateChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBD4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2C4432)),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2C4432),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

