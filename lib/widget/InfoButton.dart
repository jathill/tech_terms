import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
import 'package:tech_terms/database.dart';

class InfoButton extends StatelessWidget {
  InfoButton({@required this.context, @required this.onSendAttempt});

  final Color buttonColor = Colors.blue;
  final BuildContext context;
  final Function onSendAttempt;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info),
      onPressed: _show,
      color: Theme.of(context).accentColor,
    );
  }

  Future<Null> _show() async {
    final int version = await TermDatabase.get().getLocalVersion();

    return showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Info", textAlign: TextAlign.center),
          contentPadding: const EdgeInsets.all(12.0),
          content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            const Text(
              "Copyright © 2018 Justin Athill",
              textAlign: TextAlign.center,
            ),
            const Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: const Text(
                  "jcathill@gmail.com",
                )),
            FlatButton(
                onPressed: _launchURL,
                child: Text("Website",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: buttonColor, fontSize: 17.0))),
            FlatButton(
                onPressed: _openTextField,
                child: Text("Feedback / Make a suggestion",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: buttonColor, fontSize: 17.0))),
            Text(
              "\nData Version: $version",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ]),
          actions: <Widget>[
            FlatButton(
              child: Text('Close', style: TextStyle(color: buttonColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _launchURL() async {
    const String url = "https://tech-terms.herokuapp.com";
    await launch(url, forceSafariVC: false);
  }

  Future<Null> _openTextField() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Send Feedback", textAlign: TextAlign.center),
              contentPadding: const EdgeInsets.all(12.0),
              content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.multiline,
                  maxLines: 8,
                  autofocus: true),
              actions: <Widget>[
                FlatButton(
                  child: Text('Send', style: TextStyle(color: buttonColor)),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();

                    if (await _sendEmail(controller.text))
                      onSendAttempt(3);
                    else
                      onSendAttempt(4);

                    controller.dispose();
                  },
                ),
                FlatButton(
                  child: Text('Cancel', style: TextStyle(color: buttonColor)),
                  onPressed: () {
                    controller.dispose();
                    Navigator.of(context).pop();
                  },
                )
              ]);
        });
  }

  Future<bool> _sendEmail(String content) async {
    final String pass = await rootBundle.loadString("assets/rand.txt");
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
