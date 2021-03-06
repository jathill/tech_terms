// Copyright 2018 Justin Athill

import 'package:flutter/material.dart';

class SearchBottom extends StatelessWidget {
  SearchBottom(
      {@required this.textController,
      @required this.onType,
      @required this.onClear});

  final TextEditingController textController;
  final Function onType;
  final Function onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).accentColor,
        alignment: Alignment.center,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Padding(
              padding: EdgeInsets.only(left: 15.0, right: 5.0),
              child: const Icon(Icons.search)),
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: SearchBar(
                      textController: textController,
                      onType: onType,
                      onClear: onClear)))
        ]));
  }
}

class SearchBar extends StatefulWidget {
  SearchBar(
      {@required this.textController,
      @required this.onType,
      @required this.onClear});

  final TextEditingController textController;
  final Function onType;
  final Function onClear;

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  Widget clearSearch;

  Widget build(BuildContext context) {
    clearSearch = widget.textController.text == ""
        ? Container()
        : ClearButton(
            onPressed: widget.onClear,
          );

    return Stack(alignment: const Alignment(1.0, 1.0), children: <Widget>[
      TextField(
          autocorrect: false,
          controller: widget.textController,
          decoration: const InputDecoration(hintText: "Search"),
          onChanged: widget.onType),
      clearSearch
    ]);
  }
}

class ClearButton extends StatelessWidget {
  ClearButton({@required this.onPressed});

  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return FlatButton(onPressed: onPressed, child: const Icon(Icons.clear));
  }
}
