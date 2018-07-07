import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';
import 'package:tech_terms/database.dart';
import 'package:tech_terms/widget/Abbreviation.dart';
import 'package:tech_terms/widget/Definition.dart';
import 'package:tech_terms/widget/Maker.dart';
import 'package:tech_terms/widget/Related.dart';
import 'package:tech_terms/widget/Tags.dart';
import 'package:tech_terms/widget/Year.dart';

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
  final _biggerFont = const TextStyle(fontSize: 18.0);
  TabController tabController;
  bool isLoading = false;
  List<Term> terms = new List();
  Map<String, List<Term>> tags = new Map();

  @override
  void initState() {
    super.initState();
    tabController = new TabController(length: 2, vsync: this);
    setState(() => isLoading = true);
    var db = TermDatabase.get();

    db.init().then((context) {
      db.getAllTerms().then((dbTerms) {
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
              child: new TabBar(
                  controller: tabController,
                  tabs: <Widget>[new Tab0(), new Tab1()]))),
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
        var col = new Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[]);

        if (t.abbreviation != null) {
          col.children.add(new Abbreviation(term: t));
        }

        col.children.add(
            new Definition(term: t, termList: terms, onPressed: _tappedTerm));

        if (t.maker != null) {
          col.children.add(new Maker(term: t));
        }

        if (t.year != null) {
          col.children.add(new Year(term: t));
        }

        if (t.tags != null) {
          col.children.add(new Tags(
            term: t,
            onPressed: _tappedTag,
          ));
        }

        if (t.related != null) {
          col.children.add(new Related(term: t, onPressed: _tappedTerm));
        }

        var body =
            new Container(padding: const EdgeInsets.all(32.0), child: col);

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
                      child: new Tab0()),
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
                      child: new Tab1()),
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
}

class Tab0 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Tab(icon: new Icon(Icons.home));
  }
}

class Tab1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Tab(icon: new Icon(Icons.menu));
  }
}
