import 'dart:async';
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
  final textController = TextEditingController();
  bool isLoading = false;
  List<Term> terms = new List();
  List<Term> fullTermList = new List();
  Map<String, List<Term>> tags = new Map();
  BuildContext _scaffoldContext;

  @override
  void initState() {
    super.initState();
    tabController = new TabController(length: 2, vsync: this);
    setState(() => isLoading = true);
    var db = TermDatabase.get();

    db.init().then((context) {
      loadTerms(db);
    });
  }

  void loadTerms(TermDatabase db) {
    db.getAllTerms().then((dbTerms) {
      setState(() {
        terms = dbTerms;
        fullTermList = dbTerms;
      });
      db.getTagMap().then((tagMap) {
        setState(() {
          tags = tagMap;
          isLoading = false;
          switchNotification(db);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text('TechTerms'),
          bottom: tabController.index != 0
              ? null
              : new PreferredSize(
                  preferredSize: const Size.fromHeight(25.0),
                  child: Container(
                      margin: EdgeInsets.only(bottom: 5.0),
                      color: Colors.amber,
                      alignment: Alignment.center,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Icon(Icons.search),
                            new Container(
                                margin: const EdgeInsets.only(
                                    left: 10.0, right: 10.0),
                                width: 300.0,
                                child: getSearchBar())
                          ])),
                )),
      body: new Builder(builder: (BuildContext context) {
        _scaffoldContext = context;

        return isLoading
            ? new Center(child: new CircularProgressIndicator())
            : new TabBarView(
                children: <Widget>[_buildFullTermList(), _buildTagList()],
                controller: tabController,
              );
      }),
      bottomNavigationBar: new Hero(
          tag: "bottom",
          child: new Material(
              color: Colors.amber,
              child: new TabBar(
                  controller: tabController,
                  tabs: <Widget>[new Tab0(), new Tab1()]))),
    );
  }

  void showMessage(String msg, Color c) {
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(
        content: new Text(msg),
        duration: new Duration(seconds: 3),
        backgroundColor: c));
  }

  void switchNotification(TermDatabase db) {
    switch (db.notificationCode) {
      case 0:
        showMessage("Could not contact server: using sample terms", Colors.red);
        break;
      case 1:
        showMessage(
            "Could not contact server: terms may be out-of-date", Colors.red);
        break;
      case 2:
        showMessage("Updated terms", Colors.green);
        break;
      default:
    }
  }

  Widget getSearchBar() {
    return new Stack(alignment: const Alignment(1.0, 1.0), children: <Widget>[
      new TextField(
          controller: textController,
          decoration: new InputDecoration(hintText: "Search terms..."),
          onChanged: (a) async {
            String currentText = textController.text;

            if (currentText == "") {
              setState(() {
                terms = fullTermList;
              });
            } else {
              List<Term> results = new List();
              fullTermList.forEach((Term t) {
                if (t.name.toLowerCase().contains(currentText.toLowerCase()))
                  results.add(t);
              });
              setState(() {
                terms = results;
              });
            }
          }),
      textController.text == ""
          ? new Container()
          : new FlatButton(
              onPressed: () {
                textController.clear();
                setState(() {
                  terms = fullTermList;
                });
              },
              child: new Icon(Icons.clear))
    ]);
  }

  Widget _buildFullTermList() {
    return _buildTermList(terms);
  }

  Widget _buildTermList(termList) {
    return new RefreshIndicator(
        child: new ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: termList.length * 2,
            itemBuilder: (context, i) {
              // Add a one-pixel-high divider widget before each row in theListView.
              if (i.isOdd) return new Divider();
              final index = i ~/ 2;
              return _buildTermRow(termList[index]);
            }),
        onRefresh: _handleRefresh);
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

  Future<Null> _handleRefresh() async {
    var db = TermDatabase.get();
    await db.refresh().then((context) => loadTerms(db));
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
