import 'package:flutter/material.dart';
import '../utils/passwords_data_handler.dart';

class SearchStateProvider extends ChangeNotifier {
  int state = 0;
  int resLen = searchResult.length;

  bool get isSearchShowing => state == 1;
  int get getSearchResLen => resLen;

  //_state = 0 indicates normal display mode
  //_state = 1 indicates search mode
  void setSearchState(int _state) {
    state = _state;
    notifyListeners();
  }

  void updateSearchResLen() {
    resLen = searchResult.length;
    notifyListeners();
  }
}
