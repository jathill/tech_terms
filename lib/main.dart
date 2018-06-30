import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';
import 'package:tech_terms/database.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'TechTerms',
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

class TermDictionaryState extends State<TermDictionary>
    with SingleTickerProviderStateMixin {
  TabController tabController;
  List<Term> terms = new List();
  List<String> tagNames = new List();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  void initState() {
    super.initState();
    tabController = new TabController(length: 2, vsync: this);
    var db = TermDatabase.get();
    db.init().then((context) {
      db.getAllTerms().then((dbTerms) {
        if (dbTerms == null) return;
        setState(() => terms = dbTerms);
      });
      db.getTagNames().then((names) {
        setState(() => tagNames = names);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('TechTerms'),
      ),
      body: new TabBarView(
        children: <Widget>[_buildTermList(), _buildTagList()],
        controller: tabController,
      ),
      bottomNavigationBar: new Material(
          color: Colors.amber,
          child: new TabBar(controller: tabController, tabs: <Widget>[
            new Tab(child: new Icon(Icons.view_list)),
            new Tab(child: new Icon(Icons.menu))
          ])),
    );
  }

  Widget _buildTermList() {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: terms.length * 2,
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return new Divider();
          final index = i ~/ 2;
          return _buildTermRow(terms[index]);
        });
  }

  Widget _buildTermRow(Term t) {
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

  Widget _buildTagList() {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tagNames.length * 2,
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return new Divider();
          final index = i ~/ 2;
          return _buildTagRow(tagNames[index]);
        });
  }

  Widget _buildTagRow(String t) {
    return new ListTile(title: new Text(t, style: _biggerFont));
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
