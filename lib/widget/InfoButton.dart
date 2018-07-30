import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:tech_terms/database.dart';

class InfoButton extends StatelessWidget {
  const InfoButton({@required this.context});

  final BuildContext context;
  @override
  Widget build(BuildContext context) {
    return new IconButton(
      icon: const Icon(Icons.info),
      onPressed: _show,
      color: Colors.indigo[100],
    );
  }

  Future<Null> _show() async {
    int version = await TermDatabase.get().getLocalVersion();

    return showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text("Info", textAlign: TextAlign.center),
          contentPadding: EdgeInsets.all(12.0),
          content:
              new Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            new Text(
              "Copyright © 2018 Justin Athill",
              textAlign: TextAlign.center,
            ),
            new Text("jcathill@gmail.com"),
            new FlatButton(
                onPressed: _launchURL,
                child: new Text("Go to website",
                    style: new TextStyle(color: Colors.blue, fontSize: 17.0))),
            new Text("\nData Version: $version"),
          ]),
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

  _launchURL() async {
    const String url = "https://tech-terms.herokuapp.com";
    await launch(url, forceSafariVC: false);
  }
}
