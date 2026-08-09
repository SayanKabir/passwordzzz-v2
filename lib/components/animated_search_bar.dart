import 'package:flutter/material.dart';
import 'package:passwordzzz_v2/providers/theme_provider.dart';
import 'package:passwordzzz_v2/providers/search_state_provider.dart';
import 'package:provider/provider.dart';

import '../utils/passwords_data_handler.dart';

class AnimatedSearchBar extends StatefulWidget {
  final TextEditingController textController;

  const AnimatedSearchBar({Key? key, required this.textController}) : super(key: key);

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  bool _folded = true;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.read<ThemeProvider>().isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: _folded ? 60 : MediaQuery.of(context).size.width * 0.75,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: _folded
                ? Container()
                : Container(
              padding: const EdgeInsets.only(left: 0),
              child: TextField(
                autofocus: true,
                controller: widget.textController,
                onChanged: (val) {
                  // Update the search results list
                  updateSearchList(val);
                  // Show the search results overlay
                  Provider.of<SearchStateProvider>(context, listen: false).setSearchState(1);
                  Provider.of<SearchStateProvider>(context, listen: false).updateSearchResLen();
                },
                decoration: InputDecoration(
                  prefixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _folded = true;
                        widget.textController.clear();
                        Provider.of<SearchStateProvider>(context, listen: false).setSearchState(0);
                      });
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 30,
                      color: isDarkMode
                          ? const Color(0xffddfffa)
                          : const Color(0xff0ba99b).withOpacity(0.7),
                    ),
                  ),
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              searchResult.clear();
              context.read<SearchStateProvider>().updateSearchResLen();
              if(_folded){
                setState(() {
                  _folded = false;
                  context.read<SearchStateProvider>().setSearchState(1);
                });
              } else {
                widget.textController.clear();
              }
            },
            icon: Padding(
              padding: const EdgeInsets.only(left: 5, top: 5),
              child: Icon(
                _folded ? Icons.search_rounded : Icons.close_rounded,
                size: _folded ? 30 : 20,
                color: isDarkMode
                    ? const Color(0xffddfffa)
                    : const Color(0xff0ba99b).withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
