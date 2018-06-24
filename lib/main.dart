import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';
import 'package:tech_terms/database.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Startup Name Generator',
      theme: new ThemeData(
        primaryColor: Colors.amber,
      ),
      home: new TermDictionary(),
    );
  }
}

class TermDictionary extends StatefulWidget {
  @override
  createState() => new TermDictionaryState();
}

class TermDictionaryState extends State<TermDictionary> {
  List<Term> terms = new List();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  void initState() {
    super.initState();
    TermDatabase.get().init();
    TermDatabase.get().getAllTerms().then((dbTerms) {
      if (dbTerms == null) return;
      setState(() {
        terms = dbTerms;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('TechTerms'),
      ),
      body: _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: terms.length * 2,
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return new Divider();
          final index = i ~/ 2;
          return _buildRow(terms[index]);
        });
  }

  Widget _buildRow(Term t) {
    return new ListTile(
      title: new Text(
        t.name,
        style: _biggerFont,
      ),
      onTap: () {
        _tappedTerm(t);
      },
    );
  }

  void _tappedTerm(Term t) {
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        var definitionWidget = new Padding(
            padding: new EdgeInsets.only(bottom: 32.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                new Container(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: new Text(
                    Term.db_definition,
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                new Text(
                  t.definition,
                  style: new TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ));

        var mainColumn = new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            definitionWidget,
          ],
        );

        if (t.maker != null) {
          mainColumn.children.add(new Padding(
              padding: new EdgeInsets.only(bottom: 32.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  new Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: new Text(
                      Term.db_maker,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  new Text(
                    t.maker,
                    style: new TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              )));
        }

        if (t.year != null) {
          mainColumn.children.add(new Padding(
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
                    t.year.toString(),
                    style: new TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              )));
        }

        var termInfo = new Container(
            padding: const EdgeInsets.all(32.0), child: mainColumn);

        return new Scaffold(
          appBar: new AppBar(
            title: new Text(t.name),
          ),
          body: termInfo,
        );
      }),
    );
  }
}
