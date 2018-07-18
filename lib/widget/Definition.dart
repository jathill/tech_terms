import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';

class Definition extends StatelessWidget {
  const Definition(
      {@required this.term, @required this.termList, @required this.onPressed});

  final Term term;
  final List<Term> termList;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    var defContent;

    if (term.abbreviates != null) {
      Term linkedAbbr =
          termList.firstWhere((Term t) => t.name == term.abbreviates);
      Text defText = new Text(term.definition);
      defContent = new FlatButton(
          textColor: Colors.lightBlue,
          onPressed: () => onPressed(linkedAbbr),
          child: defText);
    } else {
      defContent = new Text(
        term.definition,
        style: new TextStyle(
          fontSize: 18.0,
          color: Colors.grey[500],
        ),
      );
    }

    return new Padding(
        padding: new EdgeInsets.only(bottom: 32.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            new Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: new Text(Term.db_definition,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            ),
            defContent
          ],
        ));
  }
}
