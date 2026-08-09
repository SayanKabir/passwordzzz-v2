import 'dart:ui';
import 'package:flutter/material.dart';
import 'password_unit.dart';
import '../utils/passwords_data_handler.dart';

enum ListViewForm { MANAGER, SEARCH }

Widget getSearchOverlay(bool show, int _len) {
  // print("Total items: ${totalList.length}");
  // print("Search results: ${searchResult.length}  $_len");
  if (show) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.transparent,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 125, horizontal: 0),
            itemCount: _len,
            itemBuilder: (context, index) {
              return PasswordUnit(
                notifyParent: () {},
                id: searchResult[index].id ?? -1,
                kSite: searchResult[index].Site,
                kUsername: searchResult[index].Username,
                form: ListViewForm.SEARCH,
              );
            },
          ),
        ),
      ),
    );
  } else {
    return const SizedBox.shrink();
  }
}
