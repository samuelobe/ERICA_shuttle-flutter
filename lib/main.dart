import 'dart:async';

import 'package:HYBUS/GbisCardBuilder.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'FutureBuilder.dart';
import 'bus_query.dart';
import 'const.dart';
import 'reusable_card.dart';
import 'shuttle_query.dart';
import 'subway_query.dart';
import 'topisCardBuilder.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //make devices portrait. Prevent rotate.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'HYBUS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'HYBUS'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  Future<Timetable> shuttlecock_i;
  Future<Timetable> shuttlecock_o;
  Future<Timetable> giksa;
  Future<Timetable> subway;
  Future<Timetable> yesulin;

  Future<Bus> bus_3102;
  Future<Subway> subway_4_upper;
  Future<Subway> subway_4_lower;

  final RefreshController _refreshController = RefreshController();

  AppLifecycleState _lastLifecycleState;
  Timer timer;

  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    shuttlecock_i = fetchData("shuttlecock_i");
    shuttlecock_o = fetchData("shuttlecock_o");
    giksa = fetchData("giksa");
    subway = fetchData("subway");
    yesulin = fetchData("yesulin");

    bus_3102 = queryBus("216000379");
    subway_4_upper = querySubway("subway_4_upper");
    subway_4_lower = querySubway("subway_4_lower"); //4호선. 추후 수인선 개통시 파라미터만 바꿔서 호출.

    // refresh every 60 sec .
    timer = Timer.periodic(Duration(seconds: 60), (Timer t) => refreshData());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecycleState = state;
      if (state == AppLifecycleState.resumed) {
        // resume timer to live fetchData
        // 59sec due to `await Future.delayed(Duration(milliseconds: 1000));`
        refreshData();
        timer = Timer.periodic(Duration(seconds: 59), (Timer t) => refreshData());
      }
    });
  }

  void _onRefreshing() async {
    // monitor network fetch
    shuttlecock_i = fetchData("shuttlecock_i");
    shuttlecock_o = fetchData("shuttlecock_o");
    giksa = fetchData("giksa");
    subway = fetchData("subway");
    yesulin = fetchData("yesulin");
    bus_3102 = queryBus("216000379");
    subway_4_upper = querySubway("subway_4_upper");
    subway_4_lower = querySubway("subway_4_lower");
    setState(() {});

    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()

    _refreshController.loadComplete();
  }

  void refreshData() async {
    // when user in background, paused live fetchData
    switch (_lastLifecycleState) {
      case AppLifecycleState.inactive:
        timer.cancel();
        break;
      case AppLifecycleState.paused:
        timer.cancel();
        break;
      case AppLifecycleState.detached:
        timer.cancel();
        break;
      case AppLifecycleState.resumed:
    }
    shuttlecock_i = fetchData("shuttlecock_i");
    shuttlecock_o = fetchData("shuttlecock_o");
    giksa = fetchData("giksa");
    subway = fetchData("subway");
    yesulin = fetchData("yesulin");
    bus_3102 = queryBus("216000379");
    subway_4_upper = querySubway("subway_4_upper");
    subway_4_lower = querySubway("subway_4_lower");
    setState(() {});

    await Future.delayed(Duration(milliseconds: 1000));
    print("새로고침");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffffffff),
        title: Text('HYBUS', style: kAppbarText),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        header: WaterDropMaterialHeader(),
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 1));
          _onRefreshing();
          _refreshController.refreshCompleted();
        },
//        onLoading: _onRefreshing,
        child: Column(
          children: <Widget>[
            CarouselSlider(
              height: 100.0,
              items: [
                BUS_3102(bus_3102: bus_3102),
                SUBWAY_4(subway_4: subway_4_upper), //상행선
                SUBWAY_4(subway_4: subway_4_lower), //하행선
              ].map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      child: i,
                    );
                  },
                );
              }).toList(),
            ),
//            BUS_3102(bus_3102: bus_3102),
            Expanded(
              child: ReusableCard(
                color: Colors.white,
                height: (MediaQuery.of(context).size.height) * 0.17,
                cardChild: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("셔틀콕", style: kDestinationText),
                        ],
                      ),
                    ),
                    buildFutureBuilder(shuttlecock_o),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ReusableCard(
                      color: Colors.white,
                      height: (MediaQuery.of(context).size.height) * 0.17,
                      cardChild: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("셔틀콕\n건너편", style: kDestinationText),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          buildFutureBuilder(shuttlecock_i)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ReusableCard(
                      color: Colors.white,
                      height: (MediaQuery.of(context).size.height) * 0.17,
                      cardChild: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("한대앞", style: kDestinationText),
                              ],
                            ),
                          ),
                          buildFutureBuilder(subway)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ReusableCard(
                      color: Colors.white,
                      height: (MediaQuery.of(context).size.height) * 0.17,
                      cardChild: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("예술인\n아파트", style: kDestinationText),
                              ],
                            ),
                          ),
                          buildFutureBuilder(yesulin),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ReusableCard(
                      color: Colors.white,
                      height: (MediaQuery.of(context).size.height) * 0.17,
                      cardChild: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("기숙사", style: kDestinationText),
                              ],
                            ),
                          ),
                          buildFutureBuilder(giksa),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
