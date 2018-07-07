import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';

class Abbreviation extends StatelessWidget {
  const Abbreviation({@required this.term});

  final Term term;

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
                Term.db_abbreviation,
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            new Text(
              term.abbreviation,
              style: new TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ));
  }
}
