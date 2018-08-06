// Copyright 2018 Justin Athill

import 'package:flutter/material.dart';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';

typedef double GetOffsetMethod();
typedef void SetOffsetMethod(double offset);

class StatefulListView extends StatefulWidget {
  StatefulListView(
      {Key key,
      @required this.getOffsetMethod,
      @required this.setOffsetMethod,
      @required this.itemCount,
      @required this.itemBuilder,
      this.useDraggable = false,
      this.draggableColor,
      this.draggableHeight,
      this.padding,
      this.jumpToTop = false,
      this.canRefresh = false,
      this.onRefresh})
      : super(key: key);

  final GetOffsetMethod getOffsetMethod;
  final SetOffsetMethod setOffsetMethod;
  final EdgeInsets padding;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool jumpToTop;
  final bool useDraggable;
  final bool canRefresh;
  final Function onRefresh;
  final Color draggableColor;
  final double draggableHeight;

  @override
  _StatefulListViewState createState() => new _StatefulListViewState();
}

class _StatefulListViewState extends State<StatefulListView> {
  ScrollController scrollController;

  @override
  void initState() {
    super.initState();


    if (widget.jumpToTop)
      scrollController = ScrollController();
    else {
      scrollController =
          new ScrollController(initialScrollOffset: widget.getOffsetMethod());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jumpToTop) scrollController = ScrollController();

    Widget listView = ListView.builder(
      controller: scrollController,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );

    NotificationListenerCallback callback = (notification) {
      if (notification is ScrollNotification) {
        widget.setOffsetMethod(notification.metrics.pixels);
      }
    };

    if (widget.useDraggable) {
      listView = DraggableScrollbar.semicircle(
          heightScrollThumb: 70.0,
          backgroundColor: widget.draggableColor,
          controller: scrollController,
          child: listView);
    }

    if (widget.canRefresh) {
      listView = RefreshIndicator(child: listView, onRefresh: widget.onRefresh);
    }

    return NotificationListener(
      child: listView,
      onNotification: callback,
    );
  }
}
