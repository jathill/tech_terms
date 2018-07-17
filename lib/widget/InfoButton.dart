import 'package:flutter/material.dart';
import 'dart:async';

class InfoButton extends StatelessWidget {
  const InfoButton({@required this.context});

  final BuildContext context;
  @override
  Widget build(BuildContext context) {
    return new IconButton(icon: const Icon(Icons.info), onPressed: _show, color: Colors.indigo[100],);
  }

  Future<Null> _show() async {
    return showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text("Info", textAlign: TextAlign.center),
          contentPadding: EdgeInsets.all(12.0),
          content: new Text(
            "Copyright © 2018 Justin Athill\n\nContact: jcathill@gmail.com",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
