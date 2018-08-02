import 'dart:async';
import 'package:flutter/material.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:tech_terms/Term.dart';
import 'package:tech_terms/database.dart';
import 'package:tech_terms/widget/Abbreviation.dart';
import 'package:tech_terms/widget/Definition.dart';
import 'package:tech_terms/widget/InfoButton.dart';
import 'package:tech_terms/widget/Maker.dart';
import 'package:tech_terms/widget/Related.dart';
import 'package:tech_terms/widget/Tags.dart';
import 'package:tech_terms/widget/Year.dart';

typedef void ArgFunction(a, b);

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'TechTerms',
      theme: new ThemeData(
        primaryColor: Colors.indigo,
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
  final textController = TextEditingController();

  TabController tabController;
  bool isLoading = false;
  List<Term> terms = new List();
  List<Term> fullTermList = new List();
  Map<String, List<Term>> tags = new Map();
  BuildContext _scaffoldContext;
  PreferredSize bottom;
  PreferredSize searchBottom;
  Widget searchClear = Container();

  Color defaultColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    tabController = new TabController(length: 3, vsync: this);
    tabController.addListener(updateBottom);
    setState(() => isLoading = true);
    var db = TermDatabase.get();

    db.init().then((context) {
      loadTerms(db);
    });
  }

  void loadTerms(TermDatabase db) {
    db.getAllTerms().then((dbTerms) {
      setState(() {
        if (textController.text == "")
          terms = dbTerms;
        else
          terms = search(textController.text);
        fullTermList = dbTerms;
        bottom = updateBottom();
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
          title: tabController.index == 0
              ? new Text('TechTerms')
              : tabController.index == 1 ? new Text('Tags') : new Text('Saved'),
          actions: <Widget>[new InfoButton(context: context)],
          bottom: tabController.index != 0
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(25.0),
                  child: SearchBottom(
                      tabController: tabController,
                      textController: textController,
                      onChanged: handleSearchBottom,
                      searchClear: searchClear),
                )),
      body: new Builder(builder: (BuildContext context) {
        _scaffoldContext = context;

        return isLoading
            ? new Center(child: new CircularProgressIndicator())
            : new TabBarView(
                children: <Widget>[
                  _buildFullTermList(),
                  _buildTagList(),
                  _buildSavedTermList()
                ],
                controller: tabController,
              );
      }),
      bottomNavigationBar: new Hero(
          tag: "bottom",
          child: new Material(
              color: defaultColor,
              child: new TabBar(
                  indicatorColor: Colors.indigo[100],
                  controller: tabController,
                  tabs: <Widget>[new Tab0(), new Tab1(), new Tab2()]))),
    );
  }

  void handleSearchBottom() {
    String currentText = textController.text;

    if (currentText == "") {
      setState(() {
        terms = fullTermList;
        searchClear = Container();
      });
    } else {
      List<Term> results = search(currentText);
      setState(() {
        terms = results;
        searchClear = getClearButton();
      });
    }
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

  Widget updateBottom() {
    setState(() {
      if (tabController.index == 0) {
        bottom = searchBottom;
      } else
        bottom = null;
    });
    return bottom;
  }

  List<Term> search(currentText) {
    List<Term> results = new List();
    fullTermList.forEach((Term t) {
      if (t.name.toLowerCase().startsWith(currentText.toLowerCase()))
        results.add(t);
    });
    fullTermList.forEach((Term t) {
      if (t.name.toLowerCase().contains(currentText.toLowerCase())) if (!results
          .contains(t)) results.add(t);
    });

    return results;
  }

  Widget getClearButton() {
    return new FlatButton(
        onPressed: () {
          textController.clear();
          handleSearchBottom();
        },
        child: new Icon(Icons.clear));
  }

  Widget _buildFullTermList() {
    return _buildTermList(terms);
  }

  Widget _buildSavedTermList() {
    List<Term> starred = List<Term>.from(fullTermList.where((t) => t.starred));
    return _buildTermList(starred);
  }

  Widget _buildTermList(termList) {
    ScrollController scrollController = ScrollController();
    return new RefreshIndicator(
        child: DraggableScrollbar.arrows(
            backgroundColor: Colors.indigo[100],
            controller: scrollController,
            child: new ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: termList.length * 2,
                itemBuilder: (context, i) {
                  // Add a one-pixel-high divider widget before each row in theListView.
                  if (i.isOdd) return new Divider();
                  final index = i ~/ 2;
                  return _buildTermRow(termList[index]);
                })),
        onRefresh: _handleRefresh);
  }

  Widget _buildTermRow(Term t) {
    return new ListTile(
      title: new Text(
        t.name,
        style: _biggerFont,
      ),
      trailing: new IconButton(
          icon: Icon(t.starred ? Icons.star : Icons.star_border,
              color: t.starred ? Colors.yellow[600] : null),
          onPressed: () {
            setState(() {
              TermDatabase.get().updateStarred(t);
            });
          }),
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

  void _toggleStarred(Term t) {
    setState(() {
      TermDatabase.get().updateStarred(t);
    });
  }

  void _tappedTerm(Term t) {
    Navigator.of(_scaffoldContext).push(
      new MaterialPageRoute(builder: (context) {
        var col = new Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[]);

        if (t.abbreviation != null) {
          col.children.add(new Abbreviation(term: t));
        }

        col.children.add(new Definition(
            term: t, termList: fullTermList, onPressed: _tappedTerm));

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

        var body = ListView(children: <Widget>[
          new Container(padding: const EdgeInsets.all(32.0), child: col)
        ]);

        return new Scaffold(
          appBar: PreferredSize(
              child: TermAppBar(term: t, onChanged: _toggleStarred),
              preferredSize: Size.fromHeight(kToolbarHeight)),
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
            color: defaultColor,
            child: new TabBar(
                indicatorColor: Colors.indigo[100],
                controller: tabController,
                tabs: <Widget>[
                  new GestureDetector(
                      child: new Container(
                          color: defaultColor,
                          width: double.infinity,
                          child: new Tab0()),
                      onTap: () {
                        while (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        setState(() {
                          if (tabController.index != 0) tabController.index = 0;
                        });
                      }),
                  new GestureDetector(
                      child: new Container(
                          color: defaultColor,
                          width: double.infinity,
                          child: new Tab1()),
                      onTap: () {
                        while (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        setState(() {
                          if (tabController.index != 1) tabController.index = 1;
                        });
                      }),
                  new GestureDetector(
                      child: new Container(
                          color: defaultColor,
                          width: double.infinity,
                          child: new Tab2()),
                      onTap: () {
                        while (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        setState(() {
                          if (tabController.index != 2) tabController.index = 2;
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

class SearchBottom extends StatelessWidget {
  SearchBottom(
      {@required this.tabController,
      @required this.textController,
      @required this.onChanged,
      @required this.searchClear});

  final TabController tabController;
  final TextEditingController textController;
  final Function onChanged;
  final Widget searchClear;

  Widget build(BuildContext context) {
    return new Container(
        color: Colors.indigo[100],
        alignment: Alignment.center,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          new Icon(Icons.search),
          new Container(
              margin: const EdgeInsets.only(left: 10.0, right: 10.0),
              width: 300.0,
              child: getSearchBar())
        ]));
  }

  Widget getSearchBar() {
    return new Stack(alignment: const Alignment(1.0, 1.0), children: <Widget>[
      new TextField(
          autocorrect: false,
          controller: textController,
          decoration: new InputDecoration(hintText: "Search terms..."),
          onChanged: (context) async {
            onChanged();
          }),
      searchClear
    ]);
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
    return new Tab(icon: new Icon(Icons.collections_bookmark));
  }
}

class Tab2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Tab(icon: new Icon(Icons.star));
  }
}

class TermAppBar extends StatefulWidget {
  TermAppBar({@required this.term, @required this.onChanged});

  final Term term;
  final ValueChanged<Term> onChanged;

  @override
  _TermAppBarState createState() => _TermAppBarState();
}

class _TermAppBarState extends State<TermAppBar> {
  bool starred;

  void _handleChanged() {
    setState(() {
      starred = !starred;
    });
    widget.onChanged(widget.term);
  }

  Widget build(BuildContext context) {
    starred = widget.term.starred;
    return new AppBar(
      title: FittedBox(
        child: new Text(widget.term.name),
        fit: BoxFit.scaleDown,
      ),
      actions: <Widget>[
        new IconButton(
            icon: new Icon(starred ? Icons.star : Icons.star_border,
                color: starred ? Colors.yellow[600] : null),
            onPressed: _handleChanged)
      ],
    );
  }
}
