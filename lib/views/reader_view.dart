import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:battery_indicator/battery_indicator.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ln_reader/novel/struct/ln_chapter.dart';
import 'package:ln_reader/scopes/global_scope.dart' as globals;

class ReaderArgs {
  ReaderArgs({this.chapter, this.markdown});

  final LNChapter chapter;
  final String markdown;
}

class ReaderView extends StatefulWidget {
  ReaderView({Key key, this.chapter, this.markdown}) : super(key: key);

  final LNChapter chapter;
  final String markdown;

  @override
  _ReaderView createState() => _ReaderView();
}

class _ReaderView extends State<ReaderView> {
  final dateFormat = DateFormat.jm();

  double startOffset = 0.0;
  String time;
  DateTime startTime;

  ScrollController controller;
  double percentRead = 0.0;
  Timer timeTimer;
  Timer remainingTimer;
  String timeRemaining;

  bool showNavs = false;

  @override
  void initState() {
    super.initState();

    globals.readerFontFamily.bind(this);
    globals.readerFontSize.bind(this);

    _setTime();
    startTime = DateTime.now();

    startOffset = widget.chapter.lastPosition;

    if (controller != null) {
      controller.dispose();
    }

    controller = ScrollController(initialScrollOffset: startOffset);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.chapter.scrollLength = controller.position.maxScrollExtent;

      percentRead =
          (controller.offset / controller.position.maxScrollExtent) * 100.0;

      controller.addListener(() {
        widget.chapter.lastPosition = controller.offset;
        widget.chapter.scrollLength = controller.position.maxScrollExtent;
        setState(() {
          percentRead =
              (controller.offset / controller.position.maxScrollExtent) * 100.0;
        });
      });

      // Update the clock every minute
      timeTimer = Timer.periodic(Duration(minutes: 1), (_) => _setTime());

      // Update time remaining every 10 seconds
      remainingTimer =
          Timer.periodic(Duration(seconds: 10), (_) => _setTimeRemaining());
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(
      [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    timeTimer.cancel();
    remainingTimer.cancel();
    globals.writeToFile(); // sync globals upon closing reader
    super.dispose();
  }

  _setTime() {
    if (mounted) {
      setState(() {
        time = dateFormat.format(DateTime.now().toLocal());
      });
    }
  }

  _setTimeRemaining() {
    // Care for divide by 0 errors
    if (mounted &&
        controller
            .positions.isNotEmpty && // ignore: invalid_use_of_protected_member
        !(controller.offset == 0 || (controller.offset - startOffset) == 0)) {
      // Calculate time taken
      final timeTaken = DateTime.now().difference(startTime);
      // Calculate minutes remaining: (time_taken / units_processed) * units_remaining
      int remMins = ((timeTaken.inMinutes / (controller.offset - startOffset)) *
              (controller.position.maxScrollExtent - controller.offset))
          .floor();
      int remHours = (remMins / 60).floor();
      remMins = (remMins % 60).floor();
      // Update the timeRemaining variable
      setState(() {
        timeRemaining = !(remHours == 0 && remMins == 0)
            ? (remHours.toString() + 'h' + remMins.toString() + 'm')
            : null;
      });
    }
  }

  TextStyle _smallStyle() =>
      Theme.of(context).textTheme.body1.copyWith(fontSize: 10.0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
          color: Theme.of(context).primaryColor,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: showNavs ? 2.0 : 27.0,
                ),
                child: SingleChildScrollView(
                  controller: controller,
                  child: GestureDetector(
                    onTap: () {
                      showNavs = !showNavs;
                      if (showNavs) {
                        SystemChrome.setEnabledSystemUIOverlays(
                          [SystemUiOverlay.top, SystemUiOverlay.bottom],
                        );
                      } else {
                        SystemChrome.setEnabledSystemUIOverlays([]);
                      }
                    },
                    child: new MarkdownBody(
                      styleSheet: MarkdownStyleSheet.fromTheme(ThemeData(
                        textTheme: TextTheme(
                          body1: TextStyle(
                            fontFamily: globals.readerFontFamily.val,
                            fontSize: globals.readerFontSize.val,
                            color: Theme.of(context).textTheme.body1.color,
                          ),
                          body2: TextStyle(
                            fontFamily: globals.readerFontFamily.val,
                            fontSize: globals.readerFontSize.val,
                            color: Theme.of(context).textTheme.body1.color,
                          ),
                          headline: TextStyle(
                            fontFamily: globals.readerFontFamily.val,
                            fontSize: globals.readerFontSize.val * 1.33,
                            color: Theme.of(context).textTheme.headline.color,
                          ),
                          title: TextStyle(
                            fontFamily: globals.readerFontFamily.val,
                            fontSize: globals.readerFontSize.val * 2,
                            color: Theme.of(context).textTheme.headline.color,
                          ),
                          subhead: TextStyle(
                            fontFamily: globals.readerFontFamily.val,
                            fontSize: globals.readerFontSize.val * 1.175,
                            color: Theme.of(context).textTheme.headline.color,
                          ),
                        ),
                      )),
                      data: widget.markdown,
                    ),
                  ),
                ),
              ),
              // This ensures the mini status bar is on top
              !showNavs
                  ? Positioned(
                      left: 0.0,
                      top: 0.0,
                      child: Container(
                        color: Theme.of(context).primaryColor,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 25.0,
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 3.0),
                                  child: Text(
                                    time,
                                    style: _smallStyle(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.only(left: 12.0, top: 3.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.class_,
                                            size: 14.0,
                                            color: Theme.of(context)
                                                .textTheme
                                                .body1
                                                .color,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 3.0),
                                            child: Text(
                                              (percentRead.toInt().toString() +
                                                      '%') +
                                                  (timeRemaining != null
                                                      ? '   ' + timeRemaining
                                                      : ''),
                                              style: _smallStyle(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: 12.0, top: 3.0),
                                      child: BatteryIndicator(
                                        style:
                                            BatteryIndicatorStyle.skeumorphism,
                                        mainColor: Theme.of(context)
                                            .textTheme
                                            .body1
                                            .color,
                                        colorful: false,
                                        showPercentNum: false,
                                        ratio: 2.0,
                                        size: 10.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : null,
            ].where((child) => child != null).toList(),
          )),
    );
  }
}
