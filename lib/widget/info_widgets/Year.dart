// Copyright 2018 Justin Athill

import 'package:flutter/material.dart';

import 'package:tech_terms/Term.dart';

class Year extends StatelessWidget {
  const Year({@required this.term});

  final Term term;

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
                Term.db_year.replaceAll(RegExp(r'_'), ' '),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              term.year.toString(),
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.grey[500],
              ),
            ),
          ],
        ));
  }
}