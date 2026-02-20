import 'package:flutter/material.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';
import 'package:larpland/view/admin/event_register.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {

  late Future<List<RoleplayEvent>> eventList;

  @override
  void initState() {
    super.initState();
    eventList = fetchEventList();
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<RoleplayEvent>>(
          future: eventList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('Sin eventos'));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data![index].name),
                    subtitle: Text(snapshot.data![index].fechaInicio.toString()),
                    trailing: Text(snapshot.data![index].fechaFin.toString()),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () =>
                Navigator.push(context, 
                MaterialPageRoute(builder: (context) => const AddEventScreen())),
            tooltip: 'Agregar evento',
            heroTag: 'add_event',
            child: const Icon(Icons.add),
          ),
        )
      ],
    );
  }
}
