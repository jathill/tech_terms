import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';

class Definition extends StatelessWidget {
  Definition(
      {@required this.term, @required this.termList, @required this.onPressed});

  final Term term;
  final List<Term> termList;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    Widget defContent;

    if (term.abbreviates != null) {
      Term linkedAbbr =
          termList.firstWhere((Term t) => t.name == term.abbreviates);
      Text defText = Text(term.definition);
      defContent = FlatButton(
          textColor: Colors.lightBlue,
          onPressed: () => onPressed(linkedAbbr),
          child: defText);
    } else {
      defContent = Text(
        term.definition,
        style: TextStyle(
          fontSize: 18.0,
          color: Colors.grey[500],
        ),
      );
    }

    return Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(Term.db_definition,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            ),
            defContent
          ],
        ));
  }
}
