// Copyright 2018 Justin Athill

import 'package:flutter/material.dart';

import 'package:tech_terms/Term.dart';

class Tags extends StatelessWidget {
  const Tags({@required this.term, @required this.onPressed});

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
                Term.db_tags,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Wrap(
                spacing: 8.0, runSpacing: 4.0, children: _buildTagButtons(term))
          ],
        ));
  }

  List<Widget> _buildTagButtons(Term t) {
    List<Widget> buttons = [];
    t.tags.forEach((String name) {
      final OutlineButton button = OutlineButton(
        onPressed: () => onPressed(name),
        borderSide: const BorderSide(color: Colors.lightBlue),
        textColor: Colors.blueGrey,
        child: Text(
          name,
          style: const TextStyle(fontSize: 16.0),
        ),
      );
      buttons.add(button);
    });
    return buttons;
  }
}
