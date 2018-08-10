// Copyright 2018 Justin Athill

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import 'package:tech_terms/Term.dart';
import 'package:tech_terms/database.dart';
import 'package:tech_terms/widget/app_widgets.dart';
import 'package:tech_terms/widget/info_widgets.dart';

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

  BuildContext _scaffoldContext;
  TabController tabController;

  bool jumpToTop = false;
  bool animateToTop = false;
  bool isLoading = false;
  double listViewOffset0 = 0.0;
  double listViewOffset1 = 0.0;
  double listViewOffset2 = 0.0;
  List<Term> terms = List();
  List<Term> fullTermList = List();
  Map<String, List<Term>> tags = Map();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      setState(() {});
    });
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

        if (isLoading) {
          return Container(
              constraints: BoxConstraints.expand(),
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: const Text(
                            "Just a second! Downloading the latest TechTerms."))
                  ]));
        }

        return TabBarView(
          children: <Widget>[
            _buildTermList(),
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
                  tabs: <Widget>[
                    GestureDetector(
                      child: Container(
                          color: Theme.of(context).primaryColor,
                          width: double.infinity,
                          child: const Tab0()),
                      onTap: _handleHomeTap,
                    ),
                    const Tab1(),
                    const Tab2()
                  ]))),
    );
  }

  Widget _buildStarredTermList() {
    final List<Term> starred =
        List<Term>.from(fullTermList.where((t) => t.starred));
    if (starred.isEmpty)
      return Center(child: const Text("No terms have been starred"));
    else {
      GetOffsetMethod getOffsetMethod = () => listViewOffset2;
      SetOffsetMethod setOffsetMethod =
          (offset) => this.listViewOffset2 = offset;

      StatefulListView listView = StatefulListView(
        getOffsetMethod: getOffsetMethod,
        setOffsetMethod: setOffsetMethod,
        padding: const EdgeInsets.all(16.0),
        itemCount: starred.length * 2,
        itemBuilder: _getItemBuilder(starred, _buildTermRow),
        useDraggable: starred.length >= 15,
        draggableColor: Theme.of(context).primaryColor,
        draggableHeight: 70.0,
      );

      return listView;
    }
  }

  IndexedWidgetBuilder _getItemBuilder(List list, Function buildItem) {
    return (context, i) {
      if (i.isOdd) return const Divider();
      final index = i ~/ 2;
      return buildItem(list[index]);
    };
  }

  Widget _buildStandardList(List list, Function buildItem) {
    ScrollController scrollController = ScrollController();

    ListView listView = ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: list.length * 2,
        itemBuilder: _getItemBuilder(list, buildItem));

    if (list.length >= 15) {
      return DraggableScrollbar.semicircle(
          child: listView,
          controller: scrollController,
          heightScrollThumb: 70.0,
          backgroundColor: Theme.of(context).primaryColor);
    } else {
      return listView;
    }
  }

  Widget _buildTagList() {
    GetOffsetMethod getOffsetMethod = () => listViewOffset1;
    SetOffsetMethod setOffsetMethod = (offset) => this.listViewOffset1 = offset;
    List<String> tagList = List<String>.from(tags.keys);

    return StatefulListView(
      getOffsetMethod: getOffsetMethod,
      setOffsetMethod: setOffsetMethod,
      itemCount: tagList.length * 2,
      itemBuilder: _getItemBuilder(tagList, _buildTagRow),
      useDraggable: true,
      draggableColor: Theme.of(context).primaryColor,
      draggableHeight: 70.0,
      padding: const EdgeInsets.all(16.0),
    );
  }

  Widget _buildTermList() {
    GetOffsetMethod getOffsetMethod = () => listViewOffset0;
    SetOffsetMethod setOffsetMethod = (offset) => this.listViewOffset0 = offset;

    StatefulListView scroll = StatefulListView(
      getOffsetMethod: getOffsetMethod,
      setOffsetMethod: setOffsetMethod,
      padding: const EdgeInsets.all(16.0),
      itemCount: terms.length * 2,
      itemBuilder: _getItemBuilder(terms, _buildTermRow),
      useDraggable: terms.length >= 15,
      draggableColor: Theme.of(context).primaryColor,
      draggableHeight: 70.0,
      jumpToTop: jumpToTop,
      animateToTop: animateToTop,
      canRefresh: textController.text == "",
      onRefresh: _handleRefresh,
    );

    return scroll;
  }

  Widget _buildTermRow(Term t) {
    return ListTile(
      title: Text(t.name, style: _biggerFont),
      trailing: StarButton(term: t, onChanged: _toggleStarred),
      onTap: () => _tappedTerm(t),
    );
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
          body: GestureDetector(
              child: body,
              onHorizontalDragEnd: (detail) {
                if (detail.primaryVelocity >= 200) navigatorState.pop();
              }),
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
          body: GestureDetector(
              child: _buildStandardList(tags[tagName], _buildTermRow),
              onHorizontalDragEnd: (detail) {
                if (detail.primaryVelocity >= 200) navigatorState.pop();
              }),
          bottomNavigationBar: SubviewBottomBar(
              tabController: tabController,
              navigatorState: navigatorState,
              themeData: Theme.of(context),
              onChanged: _handleSubviewTabChange),
        );
      }),
    );
  }

  void _handleHomeTap() {
    int index = tabController.index;

    if (index == 0) {
      if (textController.text != "") {
        _handleSearchClear();
      }
      else {
        setState(() => animateToTop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => animateToTop = false);
        });
      }
    } else {
      tabController.animateTo(0);
    }



  }

  Future<Null> _handleRefresh() async {
    TermDatabase db = TermDatabase.get();
    await db.refresh().then((context) => loadTerms(db));
  }

  void _handleSearchTyping(String currentText) {

    if (currentText == "") {
      setState(() => terms = fullTermList);
    } else {
      List<Term> results = search(currentText);
      setState(() {
        terms = results;
        jumpToTop = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          jumpToTop = false;
        });
      });
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

    fullTermList.forEach((t) {
      if (t.name.toLowerCase().contains(currentText.toLowerCase()) &&
          !results.contains(t)) results.add(t);
    });

    return results;
  }

  void _handleSubviewTabChange(int index) {
    if (tabController.index != index)
      tabController.animateTo(index);
  }
}
