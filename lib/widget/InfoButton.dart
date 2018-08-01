import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
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
            new Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: new Text(
                  "jcathill@gmail.com",
                )),
            new FlatButton(
                onPressed: _launchURL,
                child: new Text("Website",
                    style: new TextStyle(color: Colors.blue, fontSize: 17.0))),
            new FlatButton(
                onPressed: _openTextField,
                child: new Text("Feedback / Make a suggestion",
                    style: new TextStyle(color: Colors.blue, fontSize: 17.0))),
            new Text(
              "\nData Version: $version",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ]),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Close'),
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

  _openTextField() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text("Send Feedback", textAlign: TextAlign.center),
              contentPadding: EdgeInsets.all(12.0),
              content: new TextField(
                  controller: controller,
                  keyboardType: TextInputType.multiline,
                  maxLines: 8,
                  autofocus: true),
              actions: <Widget>[
                new FlatButton(
                  child: new Text('Send'),
                  onPressed: () async {
                    var db = TermDatabase.get();
                    bool success = await _sendEmail(controller.text);

                    if (success) Navigator.of(context).pop();
                  },
                ),
                new FlatButton(
                  child: new Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        });
  }

  Future<bool> _sendEmail(String content) async {
    String pass = await rootBundle.loadString("assets/rand.txt");
    var options = new YahooSmtpOptions()
      ..username = 'justinathill'
      ..password = pass;

    var emailTransport = new SmtpTransport(options);

    var envelope = new Envelope()
      ..from = 'justinathill@yahoo.com'
      ..recipients.add('jcathill@gmail.com')
      ..subject = 'Tech Terms Feedback'
      ..text = content
      ..html = '<p>$content</p>';
    return await emailTransport.send(envelope).then((envelope) {
      return true;
    }).catchError((e) {
      print('Error occurred: $e');
      return false;
    });
  }
}
