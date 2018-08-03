import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';

class Tags extends StatelessWidget {
  const Tags({@required this.term, @required this.onPressed});

  final Term term;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: new EdgeInsets.only(bottom: 32.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            new Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: new Text(
                Term.db_tags,
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            new Wrap(
                spacing: 8.0, runSpacing: 4.0, children: buildTagButtons(term))
          ],
        ));
  }

  List<Widget> buildTagButtons(Term t) {
    List<Widget> buttons = [];
    t.tags.forEach((String name) {
      final button = new OutlineButton(
        onPressed: () => onPressed(name),
        borderSide: new BorderSide(color: Colors.lightBlue),
        textColor: Colors.blueGrey,
        child: new Text(
          name,
          style: new TextStyle(fontSize: 16.0),
        ),
      );
      buttons.add(button);
    });
    return buttons;
  }
}
