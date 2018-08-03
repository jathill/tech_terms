import 'package:flutter/material.dart';

class SearchBottom extends StatelessWidget {
  SearchBottom(
      {@required this.textController,
      @required this.onType,
      @required this.onClear});

  final TextEditingController textController;
  final Function onType;
  final Function onClear;

  Widget build(BuildContext context) {
    return new Container(
        color: Theme.of(context).accentColor,
        alignment: Alignment.center,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          new Icon(Icons.search),
          new Container(
              margin: const EdgeInsets.only(left: 10.0, right: 10.0),
              width: 300.0,
              child: SearchBar(
                  textController: textController,
                  onType: onType,
                  onClear: onClear))
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
      new TextField(
          autocorrect: false,
          controller: widget.textController,
          decoration: const InputDecoration(hintText: "Search terms..."),
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
    return new FlatButton(onPressed: onPressed, child: new Icon(Icons.clear));
  }
}
