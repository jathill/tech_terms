import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';

class Year extends StatelessWidget {
  const Year({@required this.term});

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
                Term.db_year.replaceAll(new RegExp(r'_'), ' '),
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            new Text(
              term.year.toString(),
              style: new TextStyle(
                fontSize: 18.0,
                color: Colors.grey[500],
              ),
            ),
          ],
        ));
  }
}