import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:libserialport/libserialport.dart';
import 'package:start_stop_restart/controller/count_controller_with_reactive.dart';
import 'package:start_stop_restart/function/database_helper.dart';
import 'package:start_stop_restart/monitoring.dart';
import 'package:start_stop_restart/page/chart.dart';
import 'package:start_stop_restart/widget/range_wave_length.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);
  final dbHelper = DatabaseHelper.instance;
  late FToast fToast;
  bool samplingRateVisible = false;
  void serialPortSearch() {
    List<String> availablePorts = [];
    var i = 0;
    for (String name in SerialPort.availablePorts) {
      print('시리얼포트 이름 ${++i} $name');
      availablePorts.add(name);
    }
    availablePorts.sort();
    Get.find<CountControllerWithReactive>().serialPort.assignAll([]);
    Get.find<CountControllerWithReactive>()
        .serialPort
        .assignAll(availablePorts);
    print(
        '시리얼포트 length${Get.find<CountControllerWithReactive>().serialPort.length}');
    if (!Get.find<CountControllerWithReactive>()
        .serialPort
        .contains(Get.find<CountControllerWithReactive>().selectedPort.value)) {
      if (Get.find<CountControllerWithReactive>().serialPort.length == 0)
        Get.find<CountControllerWithReactive>().selectedPort.value = '-';
      else
        Get.find<CountControllerWithReactive>().selectedPort.value =
            Get.find<CountControllerWithReactive>().serialPort.first;
    }
    print("사용가능포트: ${Get.find<CountControllerWithReactive>().serialPort}");
  }

  //쿼리가 없어서 스타트에서 에러났난??
  void _query() async {
    final allRows = await dbHelper.queryAllRows();
    List<Map<String, dynamic>> lmap = [];
    Get.find<CountControllerWithReactive>()
        .config
        .value
        .waveLengthRanges
        .assignAll(lmap);

    Get.find<CountControllerWithReactive>()
        .config
        .value
        .waveLengthRanges
        .assignAll(allRows);
    for (var i = 0;
        i < Get.find<RangeWaveLengthController>().rwls.length;
        i++) {
      // print('startast');
      final start = double.parse(Get.find<CountControllerWithReactive>()
          .config
          .value
          .waveLengthRanges[(i * 2)]["Value"]
          .toString());
      final end = double.parse(Get.find<CountControllerWithReactive>()
          .config
          .value
          .waveLengthRanges[(i * 2) + 1]["Value"]
          .toString());
      // print('start end $start $end');
      Get.find<RangeWaveLengthController>().updateRange(
        Get.find<RangeWaveLengthController>().rwls[i],
        start: start, //double.parse('${allRows[0]["Value"]}'),
        end: end, //double.parse('${allRows[1]["Value"]}'),
      );
      print('start end $start $end');
    }
    Get.find<CountControllerWithReactive>().updateConfig();

    // print(
    //     'name ${Get.find<CountControllerWithReactive>().config.value.waveLengthRanges[10]["Name"]} value ${Get.find<CountControllerWithReactive>().config.value.integrationTime}');
    // print(
    //     'name ${Get.find<CountControllerWithReactive>().config.value.waveLengthRanges[11]["Name"]} value ${Get.find<CountControllerWithReactive>().config.value.intervalTime}');
    // print(
    //     'name ${Get.find<CountControllerWithReactive>().config.value.waveLengthRanges[12]["Name"]} value ${Get.find<CountControllerWithReactive>().config.value.samplingTime}');
  }

  //쿼리가 없어서 스타트에서 에러났난??
  void _update() async {
    List<Map<String, dynamic>> values = [];

    // List<double> valueIndex = [];
    if (Get.find<RangeWaveLengthController>().rwls[0].value.tableX.length > 0) {
      for (var i = 0; i < 5; i++) {
        values.add({
          "Name": "$i-start",
          "Value": Get.find<RangeWaveLengthController>().rwls[i].value.rv.start
        });
        values.add({
          "Name": "$i-end",
          "Value": Get.find<RangeWaveLengthController>().rwls[i].value.rv.end
        });
      }
    }
    values.add({
      "Name": "integrationTime",
      "Value":
          Get.find<CountControllerWithReactive>().config.value.integrationTime
    });
    values.add({
      "Name": "interval",
      "Value": Get.find<CountControllerWithReactive>().config.value.intervalTime
    });
    values.add({
      "Name": "sampling",
      "Value": Get.find<CountControllerWithReactive>().config.value.samplingTime
    });
    if (Get.find<CountControllerWithReactive>().selectedPort.value != '-') {
      values.add({
        "Name": "serialPort",
        "Value": Get.find<CountControllerWithReactive>().config.value.serialPort
      });
    }
    Get.find<CountControllerWithReactive>().config.value.modeHemos =
        Get.find<RangeWaveLengthController>().modeHemos.value ? 1 : 0;
    Get.find<CountControllerWithReactive>().config.value.modeOES =
        Get.find<RangeWaveLengthController>().modeOES.value ? 1 : 0;
    values.add({
      "Name": "hemos",
      "Value": Get.find<CountControllerWithReactive>().config.value.modeHemos
    });
    values.add({
      "Name": "oes",
      "Value": Get.find<CountControllerWithReactive>().config.value.modeOES
    });

    for (var i = 0; i < values.length; i++) {
      Map<String, dynamic> row = {
        DatabaseHelper.name: values[i]["Name"],
        DatabaseHelper.value: values[i]["Value"],
      };

      print('row $row row(s)');
      final rowsAffected = await dbHelper.update(row);
      print('updated $rowsAffected row(s)');
    }
    _query();
  }

  Widget wgsTextField(name, hint, text, onChanged) {
    return IgnorePointer(
        ignoring: Get.find<RangeWaveLengthController>().disabledButton.value,
        child: Padding(
          padding:
              const EdgeInsets.only(right: 15, left: 15, top: 1, bottom: 1),
          child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: name,
              labelStyle: TextStyle(
                color:
                    Get.find<RangeWaveLengthController>().disabledButton.value
                        ? Colors.grey
                        : Colors.blue,
              ),
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                    color: Get.find<RangeWaveLengthController>()
                            .disabledButton
                            .value
                        ? Colors.grey
                        : Colors.blue,
                    width: 1),
              ),
            ),
            controller: TextEditingController(text: text),
            onChanged: (value) {
              onChanged(value);
            },
          ),
        ));
  }

  _showToastErrorM({required String msg}) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.redAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning),
          SizedBox(
            width: 12.0,
          ),
          Text(msg),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );
  }

  int exceptionConfig() {
    final int intergrationTime =
        Get.find<CountControllerWithReactive>().config.value.integrationTime;
    final int intervalTime =
        Get.find<CountControllerWithReactive>().config.value.intervalTime;
    if (!Get.find<RangeWaveLengthController>().modeOES.value) return 0;
    if (intergrationTime + 30 > intervalTime) {
      String a = "integration 값은 interval의 값 보다 최소한 30ms 작아야합니다. 저장하지 못했습니다.";
      _showToastErrorM(msg: a);
      return 1;
    }
    return 0;
  }

  void comparedInteraval(int value) {
    if (value + 30 >
        Get.find<CountControllerWithReactive>().config.value.intervalTime) {
      String a = "integration 값은 interval의 값 보다 최소한 30ms 작아야합니다.";
      _showToastErrorM(msg: a);
      Get.find<CountControllerWithReactive>().config.value.integrationTime =
          Get.find<CountControllerWithReactive>().config.value.intervalTime -
              30;
    }
  }

  void comparedIntegration(int value) {
    if (value <
        Get.find<CountControllerWithReactive>().config.value.integrationTime +
            30) {
      String b = "interval 값은 integration의 값 보다 최소한 30ms 커야합니다.";
      _showToastErrorM(msg: b);
      Get.find<CountControllerWithReactive>().config.value.intervalTime =
          Get.find<CountControllerWithReactive>().config.value.integrationTime +
              30;
    }
  }

  @override
  Widget build(BuildContext context) {
    fToast = FToast();
    fToast.init(context);
    _query();
    serialPortSearch();
    return Scaffold(
      appBar: AppBar(
        title: Text('WR 연습'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 10,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Monitoring(),
              ChartPage(),
            ],
          ),
        ),
      ),
    );
  }
}
