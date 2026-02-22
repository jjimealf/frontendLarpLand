import 'package:larpland/model/user.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<List<User>> fetchUserList() async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await FirebaseBackend.users.orderBy('id').get();
  return snapshot.docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map(User.fromJson)
      .toList(growable: false);
}

Future<User> showUser(int id) async {
  FirebaseBackend.ensureInitialized();
  final doc = await FirebaseBackend.findByNumericId(FirebaseBackend.users, id);
  return User.fromJson(FirebaseBackend.normalizeSnapshotData(doc));
}
