import 'package:flutter/material.dart';
import 'package:larpland/model/user.dart';
import 'package:larpland/service/user.dart';

class UsersList extends StatefulWidget {
  const UsersList({super.key});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late Future<List<User>> futureUserList;

  @override
  void initState() {
    super.initState();
    futureUserList = fetchUserList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: futureUserList,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Sin usuarios'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data![index].name),
                subtitle: Text(snapshot.data![index].email),
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
    );
  }
}
