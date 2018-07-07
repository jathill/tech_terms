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
  bool isLoading = false;
  TabController tabController;
  List<Term> terms = new List();
  Map<String, List<Term>> tags = new Map();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  void initState() {
    super.initState();
    tabController = new TabController(length: 2, vsync: this);
    setState(() => isLoading = true);
    var db = TermDatabase.get();
    db.init().then((context) {
      db.getAllTerms().then((dbTerms) {
        if (dbTerms == null) return;
        setState(() => terms = dbTerms);
      });
      db.getTags().then((tagMap) {
        setState(() {
          tags = tagMap;
          isLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('TechTerms'),
      ),
      body: isLoading
          ? new Center(child: new CircularProgressIndicator())
          : new TabBarView(
              children: <Widget>[_buildFullTermList(), _buildTagList()],
              controller: tabController,
            ),
      bottomNavigationBar: new Hero(
          tag: "bottom",
          child: new Material(
              color: Colors.amber,
              child: new TabBar(controller: tabController, tabs: <Widget>[
                new Tab(child: new Icon(Icons.home)),
                new Tab(child: new Icon(Icons.menu))
              ]))),
    );
  }

  Widget _buildFullTermList() {
    return _buildTermList(terms);
  }

  Widget _buildTermList(termList) {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: termList.length * 2,
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return new Divider();
          final index = i ~/ 2;
          return _buildTermRow(termList[index]);
        });
  }

  Widget _buildTermRow(Term t) {
    return new ListTile(
      title: new Text(
        t.name,
        style: _biggerFont,
      ),
      onTap: () => _tappedTerm(t),
    );
  }

  Widget _buildTagList() {
    List<String> tagNames = List<String>.from(tags.keys);
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
    return new ListTile(
      title: new Text(t, style: _biggerFont),
      onTap: () => _tappedTag(t),
    );
  }

  void _tappedTerm(Term t) {
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        var defContent;
        var mainColumn = new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[]
        );

        if (t.abbreviation != null) {
          mainColumn.children.add(new Padding(
              padding: new EdgeInsets.only(bottom: 32.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  new Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: new Text(
                      Term.db_abbreviation,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  new Text(
                    t.abbreviation,
                    style: new TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              )));
        }

        if (t.abbreviates != null) {
          Term linkedAbbr =
              terms.firstWhere((Term term) => term.name == t.abbreviates);
          Text defText = new Text(t.definition);
          defContent = new FlatButton(
              textColor: Colors.lightBlue,
              onPressed: () => _tappedTerm(linkedAbbr),
              child: defText);
        } else {
          defContent = new Text(
            t.definition,
            style: new TextStyle(
              color: Colors.grey[500],
            ),
          );
        }

        var definitionWidget = new Padding(
            padding: new EdgeInsets.only(bottom: 32.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                new Container(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: new Text(Term.db_definition,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                      )),
                ),
                defContent
              ],
            ));

        mainColumn.children.add(definitionWidget);

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

        if (t.tags != null) {
          mainColumn.children.add(new Padding(
              padding: new EdgeInsets.only(bottom: 32.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  new Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: new Text(
                      Term.db_tags,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  new Wrap(spacing: 8.0, children: buildTagButtons(t))
                ],
              )));
        }

        if (t.related != null) {
          mainColumn.children.add(new Padding(
              padding: new EdgeInsets.only(bottom: 32.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  new Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: new Text(
                      Term.db_related,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  new Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: buildRelatedButtons(t))
                ],
              )));
        }

        var body = new Container(
            padding: const EdgeInsets.all(32.0), child: mainColumn);

        return new Scaffold(
          appBar: new AppBar(
            title: new Text(t.name),
          ),
          body: body,
          bottomNavigationBar: _getSubviewBottomBar(),
        );
      }),
    );
  }

  Widget _getSubviewBottomBar() {
    return new Hero(
        tag: "bottom",
        child: new Material(
            color: Colors.amber,
            child: new TabBar(controller: tabController, tabs: <Widget>[
              new GestureDetector(
                  child: new Container(
                      color: Colors.amber,
                      width: double.infinity,
                      child: new Tab(
                        child: new Icon(Icons.home),
                      )),
                  onTap: () {
                    while (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    setState(() {
                      if (tabController.index == 1) tabController.index = 0;
                    });
                  }),
              new GestureDetector(
                  child: new Container(
                      color: Colors.amber,
                      width: double.infinity,
                      child: new Tab(
                        child: new Icon(Icons.menu),
                      )),
                  onTap: () {
                    while (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    setState(() {
                      if (tabController.index == 0) tabController.index = 1;
                    });
                  })
            ])));
  }

  void _tappedTag(String tagName) {
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return new Scaffold(
          appBar: new AppBar(
            title: new Text(tagName),
          ),
          body: _buildTermList(tags[tagName]),
          bottomNavigationBar: _getSubviewBottomBar(),
        );
      }),
    );
  }

  List<Widget> buildTagButtons(Term t) {
    List<Widget> buttons = [];
    t.tags.forEach((String name) {
      final button = new OutlineButton(
        onPressed: () => _tappedTag(name),
        borderSide: new BorderSide(color: Colors.lightBlue),
        textColor: Colors.blueGrey,
        child: new Text(name),
      );
      buttons.add(button);
    });
    return buttons;
  }

  List<Widget> buildRelatedButtons(Term t) {
    List<Widget> buttons = [];
    t.related.forEach((Term relatedTerm) {
      final button = new OutlineButton(
        onPressed: () => _tappedTerm(relatedTerm),
        borderSide: new BorderSide(color: Colors.lightBlue),
        textColor: Colors.blueGrey,
        child: new Text(relatedTerm.name),
      );
      buttons.add(button);
    });
    return buttons;
  }
}
