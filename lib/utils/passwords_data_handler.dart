import '../models/data_model.dart';
import '../db/local.dart';

List<Data> totalList = [];
List<Data> searchResult = [];

Future<void> getAllDataFromDB() async {
  final List datas = await sqliteDB.dataBase.getData();
  for (var data in datas) {
    Data newData = Data(
      id: data["id"],
      Site: data["site"].toString(),
      Username: data["user"].toString(),
    );
    totalList.add(newData);
  }
}

void updateSearchList(String query) {
  searchResult = totalList
      .where((element) =>
  element.Site.toLowerCase().contains(query.toLowerCase()) ||
      element.Username.toLowerCase().contains(query.toLowerCase()))
      .toList();
}
