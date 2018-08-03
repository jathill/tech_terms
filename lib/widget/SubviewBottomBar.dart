import 'package:flutter/material.dart';
import 'package:tech_terms/widget/Tabs.dart';

class SubviewBottomBar extends StatelessWidget {
  const SubviewBottomBar(
      {@required this.tabController,
      @required this.navigatorState,
      @required this.themeData,
      @required this.onChanged});

  final TabController tabController;
  final NavigatorState navigatorState;
  final ThemeData themeData;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = themeData.primaryColor;
    final Color accentColor = themeData.accentColor;
    return Hero(
        tag: "bottom",
        child: Material(
            color: primaryColor,
            child: TabBar(
                indicatorColor: accentColor,
                controller: tabController,
                tabs: <Widget>[
                  GestureTab(
                      index: 0,
                      navigatorState: navigatorState,
                      themeData: themeData,
                      onChanged: onChanged),
                  GestureTab(
                      index: 1,
                      navigatorState: navigatorState,
                      themeData: themeData,
                      onChanged: onChanged),
                  GestureTab(
                      index: 2,
                      navigatorState: navigatorState,
                      themeData: themeData,
                      onChanged: onChanged)
                ])));
  }
}

class GestureTab extends StatelessWidget {
  GestureTab(
      {@required this.index,
      @required this.navigatorState,
      @required this.themeData,
      @required this.onChanged});

  final int index;
  final NavigatorState navigatorState;
  final ThemeData themeData;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final Tab tab =
        index == 0 ? const Tab0() : index == 1 ? const Tab1() : const Tab2();
    return GestureDetector(
        child: new Container(
            color: themeData.primaryColor, width: double.infinity, child: tab),
        onTap: () {
          while (navigatorState.canPop()) {
            navigatorState.pop();
          }
          onChanged(index);
        });
  }
}
