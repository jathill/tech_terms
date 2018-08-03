import 'dart:async';
import 'package:flutter/material.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:tech_terms/Term.dart';
import 'package:tech_terms/database.dart';
import 'package:tech_terms/widget/InfoButton.dart';
import 'package:tech_terms/widget/SearchBottom.dart';
import 'package:tech_terms/widget/StarButton.dart';
import 'package:tech_terms/widget/SubviewBottomBar.dart';
import 'package:tech_terms/widget/Tabs.dart';
import 'package:tech_terms/widget/term_info/Abbreviation.dart';
import 'package:tech_terms/widget/term_info/Definition.dart';
import 'package:tech_terms/widget/term_info/Maker.dart';
import 'package:tech_terms/widget/term_info/Related.dart';
import 'package:tech_terms/widget/term_info/Tags.dart';
import 'package:tech_terms/widget/term_info/Year.dart';

typedef void ArgFunction(a, b);

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechTerms',
      theme: ThemeData(
          primaryColor: Colors.indigo, accentColor: Colors.indigo[100]),
      home: TermDictionary(),
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
  final ScrollController _scrollController = ScrollController();

  BuildContext _scaffoldContext;
  TabController tabController;

  bool isLoading = false;
  List<Term> terms = List();
  List<Term> fullTermList = List();
  Map<String, List<Term>> tags = Map();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() => setState(() {}));
    setState(() => isLoading = true);
    TermDatabase db = TermDatabase.get();

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
      });
      db.getTagMap().then((tagMap) {
        setState(() {
          tags = tagMap;
          isLoading = false;
          switchNotification(db.notificationCode);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Text appBarTitle = tabController.index == 0
        ? const Text('TechTerms')
        : tabController.index == 1 ? const Text('Tags') : const Text('Starred');

    final PreferredSize appBarBottom = tabController.index != 0
        ? null
        : PreferredSize(
            preferredSize: const Size.fromHeight(25.0),
            child: SearchBottom(
                textController: textController,
                onType: _handleSearchTyping,
                onClear: _handleSearchClear),
          );

    return new Scaffold(
      appBar: AppBar(
          title: appBarTitle,
          actions: <Widget>[
            InfoButton(context: context, onSendAttempt: switchNotification)
          ],
          bottom: appBarBottom),
      body: Builder(builder: (BuildContext context) {
        _scaffoldContext = context;

        return isLoading
            ? const Center(child: const CircularProgressIndicator())
            : TabBarView(
                children: <Widget>[
                  _buildTermList(terms),
                  _buildTagList(),
                  _buildStarredTermList()
                ],
                controller: tabController,
              );
      }),
      bottomNavigationBar: Hero(
          tag: "bottom",
          child: Material(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                  indicatorColor: Theme.of(context).accentColor,
                  controller: tabController,
                  tabs: <Widget>[const Tab0(), const Tab1(), const Tab2()]))),
    );
  }

  Widget _buildStarredTermList() {
    final List<Term> starred =
        List<Term>.from(fullTermList.where((t) => t.starred));
    if (starred.isEmpty)
      return Center(child: const Text("No terms have been starred"));
    else
      return _buildTermList(starred);
  }

  Widget _buildTermList(termList) {
    DraggableScrollbar scroll = DraggableScrollbar.semicircle(
      heightScrollThumb: 70.0,
        backgroundColor: Theme.of(context).primaryColor,
        controller: _scrollController,
        child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: termList.length * 2,
            itemBuilder: (context, i) {
              // Add a one-pixel-high divider widget before each row in theListView.
              if (i.isOdd) return const Divider();
              final index = i ~/ 2;
              return _buildTermRow(termList[index]);
            }));

    if (textController.text == "")
      return RefreshIndicator(child: scroll, onRefresh: _handleRefresh);
    else
      return scroll;
  }

  Widget _buildTermRow(Term t) {
    return ListTile(
      title: Text(t.name, style: _biggerFont),
      trailing: StarButton(term: t, onChanged: _toggleStarred),
      onTap: () => _tappedTerm(t),
    );
  }

  Widget _buildTagList() {
    final List<String> tagNames = List<String>.from(tags.keys);
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tagNames.length * 2,
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          if (i.isOdd) return const Divider();
          final index = i ~/ 2;
          return _buildTagRow(tagNames[index]);
        });
  }

  Widget _buildTagRow(String t) {
    return ListTile(
      title: Text(t, style: _biggerFont),
      onTap: () => _tappedTag(t),
    );
  }

  void _tappedTerm(Term t) {
    final NavigatorState navigatorState = Navigator.of(context);
    navigatorState.push(
      MaterialPageRoute(builder: (context) {
        Column col = Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[]);

        if (t.abbreviation != null) col.children.add(Abbreviation(term: t));
        col.children.add(Definition(
            term: t, termList: fullTermList, onPressed: _tappedTerm));
        if (t.maker != null) col.children.add(Maker(term: t));
        if (t.year != null) col.children.add(Year(term: t));
        if (t.tags != null)
          col.children.add(Tags(term: t, onPressed: _tappedTag));
        if (t.related != null)
          col.children.add(Related(term: t, onPressed: _tappedTerm));

        ListView body = ListView(children: <Widget>[
          Container(padding: const EdgeInsets.all(32.0), child: col)
        ]);

        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              child: Text(t.name),
              fit: BoxFit.scaleDown,
            ),
            actions: <Widget>[StarButton(term: t, onChanged: _toggleStarred)],
          ),
          body: body,
          bottomNavigationBar: SubviewBottomBar(
              tabController: tabController,
              navigatorState: navigatorState,
              themeData: Theme.of(context),
              onChanged: _handleSubviewTabChange),
        );
      }),
    );
  }

  void _tappedTag(String tagName) {
    final NavigatorState navigatorState = Navigator.of(context);
    navigatorState.push(
      MaterialPageRoute(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tagName),
          ),
          body: _buildTermList(tags[tagName]),
          bottomNavigationBar: SubviewBottomBar(
              tabController: tabController,
              navigatorState: navigatorState,
              themeData: Theme.of(context),
              onChanged: _handleSubviewTabChange),
        );
      }),
    );
  }

  Future<Null> _handleRefresh() async {
    TermDatabase db = TermDatabase.get();
    await db.refresh().then((context) => loadTerms(db));
  }

  void _handleSearchTyping(String currentText) {
    _scrollController.jumpTo(_scrollController.initialScrollOffset);

    if (currentText == "") {
      setState(() => terms = fullTermList);
    } else {
      List<Term> results = search(currentText);
      setState(() => terms = results);
    }
  }

  void _handleSearchClear() {
    textController.clear();
    setState(() => terms = fullTermList);
  }

  void _toggleStarred(Term t) {
    TermDatabase.get().updateStarred(t).then((nil) => setState(() {}));
  }

  void showMessage(String msg, Color c) {
    Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        backgroundColor: c));
  }

  void switchNotification(int notificationCode) {
    switch (notificationCode) {
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
      case 3:
        showMessage("Feedback sent!", Colors.green);
        break;
      case 4:
        showMessage("Could not send feedback", Colors.red);
        break;
      default:
    }
  }

  List<Term> search(currentText) {
    List<Term> results = List<Term>.from(fullTermList.where((Term t) =>
        t.name.toLowerCase().startsWith(currentText.toLowerCase())));

    results.addAll(List<Term>.from(fullTermList.where(
        (t) => t.name.toLowerCase().contains(currentText.toLowerCase()))));

    return results;
  }

  void _handleSubviewTabChange(int index) {
    if (tabController.index != index)
      setState(() {
        tabController.index = index;
      });
  }
}
