import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:start_stop_restart/controller/count_controller_with_reactive.dart';
import 'package:start_stop_restart/page/home_page.dart';
import 'package:start_stop_restart/widget/range_wave_length.dart';
import 'package:start_stop_restart/monitoring.dart';

Future main() async {
  Get.put(RangeWaveLengthController());
  Get.put(CountControllerWithReactive());
  Get.find<RangeWaveLengthController>().rwls.assignAll([]);
  Get.find<CountControllerWithReactive>().oesPoints.assignAll([]);
  for (var i = 0; i < 5; i++) {
    Get.find<RangeWaveLengthController>().rwls.add(RangeWaveLength.init().obs);
    Get.find<CountControllerWithReactive>().oesPoints.add(RxList.empty());
  }
  print('rwls length ${Get.find<RangeWaveLengthController>().rwls.length}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WR연습',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
