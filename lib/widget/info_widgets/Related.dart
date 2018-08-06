// Copyright 2018 Justin Athill

import 'package:flutter/material.dart';

import 'package:tech_terms/Term.dart';

class Related extends StatelessWidget {
  const Related({@required this.term, @required this.onPressed});

  final Term term;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                Term.db_related,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _buildRelatedButtons(term))
          ],
        ));
  }

  List<Widget> _buildRelatedButtons(Term t) {
    List<Widget> buttons = [];
    t.related.forEach((Term relatedTerm) {
      final OutlineButton button = OutlineButton(
        onPressed: () => onPressed(relatedTerm),
        borderSide: const BorderSide(color: Colors.lightBlue),
        textColor: Colors.blueGrey,
        child: Text(relatedTerm.name, style: const TextStyle(fontSize: 16.0),),
      );
      buttons.add(button);
    });
    return buttons;
  }
}
