import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:libserialport/libserialport.dart';
import 'package:start_stop_restart/controller/count_controller_with_reactive.dart';
import 'package:start_stop_restart/function/serialconnect.dart';
import 'package:start_stop_restart/widget/range_wave_length.dart';
// ignore: unused_import
import 'package:toggle_switch/toggle_switch.dart';

//fT232H가 뭔지..?
final DynamicLibrary fT232H = DynamicLibrary.open("SPdbUSBm.dll");

final DynamicLibrary wgsFunction = DynamicLibrary.open("wgsFunction.dll");

class Monitoring extends StatelessWidget {
  Monitoring({Key? key}) : super(key: key);
  RxString display = 'zzz'.obs;
  RxList<FlSpot> ys = RxList.empty();
  RxList<FlSpot> ys10 = RxList.empty();
  RxList<double> xs = RxList.empty();
  RxList<double> xsDisplay = RxList.empty();
  RxDouble displayMax = 0.0.obs;
  bool serialStart = false;
  Timer _timerHemos = Timer.periodic(Duration(seconds: 10), (time) {});
  Timer _timerAll = Timer.periodic(Duration(seconds: 10), (time) {});
  late int Function(int a) spTestAllChannels;
  late void Function(Pointer<Int16> a) spGetAssignedChannelID;
  late int Function(int a) spSetupGivenChannel;
  late int Function(int a, int b) spInitGivenChannel;
  late int Function(int a, int b) spSetIntEx;
  late int Function(Pointer<Int32> a, int b) spReadDataEx;
  late int Function(int a) serialConnect;
  int ch = -1;
  bool b10show = false;
  late FToast fToast;
  String buffer = '';

//데이터 무의미한거 처리
  String invalidData(Uint8List data) {
    String rt = '';
    if (data.length == 0) {
      print("data to short ${data.length} $data");
      return rt;
    }
    //Uint8List bytes = Uint8List.fromList(data);
    String s = String.fromCharCodes(data);
    String datas = buffer + s;

    buffer = '';
    if (datas.length < 4) {
      //print("data to short 4이하여서 추가했어");
      buffer += datas;
      return rt;
    }

    int pointIdx = datas.indexOf('.'); //1
    int commaIdx = datas.indexOf(','); //5
    int split = 0;
    if (pointIdx < 0 && commaIdx < 0) {
      print(",. 없어");
      buffer = '';
      return rt;
    } else if (pointIdx < 0) {
      split = commaIdx;
    } else if (commaIdx < 0)
      split = pointIdx;
    else
      commaIdx < pointIdx ? split = commaIdx : split = pointIdx;
    for (var i = split; i < datas.length; i += 4) {
      if (datas[i] != '.' && datas[i] != ',') {
        print('어려운거해냈어');
        buffer = '';
        return '';
      }
      ;
    }
    int length = datas.length;
    //print('wef1 ${length}');
    if ((length % 4 != 0) || (split != 3)) {
      // print('split $split');
      if (split != 3) {
        datas = datas.substring(split + 1, datas.length);
      }
      //print('datas $datas');
      length = datas.length;
      if (length % 4 != 0) {
        pointIdx = datas.lastIndexOf('.');
        commaIdx = datas.lastIndexOf(',');
        //print('pointIdx $pointIdx commaIdx$commaIdx ');
        if (pointIdx < 0 && commaIdx < 0) {
          if (length < 4)
            buffer = datas;
          else
            buffer = '';
          print("pasing한거중에도 ,. 없어");
          return rt;
        } else
          commaIdx > pointIdx ? split = commaIdx : split = pointIdx;

        buffer = datas.substring(split + 1, datas.length);
        datas = datas.substring(0, split + 1);
      }
    }

    //print('wef3');
    return datas;
  }

//복붙한것,,, <1번>관련
//시리얼, 그래프 선 만드는 메서드
  Future<int> startSerial() async {
    String selectedPort =
        Get.find<CountControllerWithReactive>().selectedPort.value;
    print("selectedPort $selectedPort");

    if (selectedPort != '-') {
      int nPort = int.parse(selectedPort.replaceAll('COM', ''));
      print("nPort $nPort");
      serialConnect(nPort);
    } else {
      return -1;
    }
    print("여기는??");
    // String choicePort = "COM5";
    var port = SerialPort(selectedPort);
    //port = SerialPort('COM11');
    port.config.baudRate = 115200;
    port.config.bits = 8;
    port.config.parity = 0;
    port.config.stopBits = 1;

    // print('serial status1 ${port.isOpen} ${port.name}');
    //port.close();

    if (!port.openReadWrite()) {
      print("open error");
      print(SerialPort.lastError);
      return -1;
    }
    print('\tDescription: ${port.description}');
    print('\tManufacturer: ${port.manufacturer}');
    print('\tSerial Number: ${port.serialNumber}');
    print('\tProduct ID: 0x${port.productId!.toRadixString(16)}');
    print('\tVendor ID: 0x${port.vendorId!.toRadixString(16)}');
    print("open success");
    // port.close();
    // return 0;
    // print("reader");

    // print('serial status2  ${port.isOpen}');
    int nVppCnt = 0;
    int nDpcrCnt = 0;
    double dpcrSum = 0.0;
    double vppSum = 0.0;
    final double divVpp = 3.3 / 4095;
    final double divDPCR = 100 / 4095;

    Stopwatch swVpp = Stopwatch();
    Stopwatch swDpcr = Stopwatch();
    final int intervalTime =
        Get.find<CountControllerWithReactive>().config.value.intervalTime;
    //print('interval $intervalTime');

    swVpp.start();
    swDpcr.start();
    //print('ddd');
    bool firstData = false;
    final reader = SerialPortReader(port);
    Future.delayed(Duration(seconds: 1), () {
      if (firstData == false) {
        _showToastError(msg: 'Hemos Data가 들어오지 않습니다.\n COM Port를 확인하세요');
      }
      return true;
    });
    Timer.periodic(Duration(microseconds: 10), (t) {
      if (serialStart == false) {
        reader.close();

        port.close();
        port.dispose();
        t.cancel();
      }
    });

    //await Future.delayed(Duration(seconds: 3));
    // print("lisetn start");
    String buffer = '';
    reader.stream.listen((data) {
      //print("data start");
      if (firstData == false) firstData = true;
      try {
        // print('ddd');
        //print('ddd $data ${data.length}');
        //if (serialStart == false) port.close();
        data.forEach((element) {
          if (element == 46) print('dpcr$data');
        });
        String datas = invalidData(data);
        // if (datas.indexOf('.') > 0) {
        //   print('=======================================');
        //   print('시간${DateTime.now()} $data');
        //   // print(
        //   //     'comma interval ${swDpcr.elapsedMilliseconds.round()} $intervalTime');
        //   a = true;
        // }
        if (datas == '') {
          return;
        }

        // String s = String.fromCharCodes(bytes);

        List<List<String>> ss = wgsSplit(datas, '.', ',');

        if (ss[0].length > 0) {
          print('dpcr raw ${ss[0]} ${ss[0].length}');
          ss[0].forEach((e) {
            dpcrSum += int.parse(e, radix: 16); // * divDPCR;
          });
          nDpcrCnt += ss[0].length;
        }

        if (ss[1].length > 0) {
          ss[1].forEach((e) {
            vppSum += int.parse(e, radix: 16) * divVpp;
          });
          nVppCnt += ss[1].length;
        }
        //nCnt += ss[1].length;
        if ((swDpcr.elapsedMilliseconds.round() >= intervalTime) &&
            (nDpcrCnt > 0)) {
          //print('interval ${swDpcr.elapsedMilliseconds.round()} $intervalTime');
          // print('dpcr $dpcrSum / $nDpcrCnt');
          swDpcr.reset();
          Get.find<CountControllerWithReactive>().dpcr.value =
              dpcrSum / nDpcrCnt;
          print('dpcr ${Get.find<CountControllerWithReactive>().dpcr.value}');
          dpcrSum = 0;
          nDpcrCnt = 0;
        }
        if ((swVpp.elapsedMilliseconds.round() >= intervalTime) &&
            (nVppCnt > 0)) {
          swVpp.reset();
          Get.find<CountControllerWithReactive>().vpp.value = vppSum / nVppCnt;
          //print('vpp $vppSum / $nVppCnt');
          vppSum = 0;
          nVppCnt = 0;
        }
      } catch (e) {
        print('문제발생 $e');
      }
    });
    return 0;
  }

//시뮬레이션데이터
  Future<void> initSimulation() async {
    List<double> xsTemp = [];
    List<double> xsDisplayTemp = [];
    xs.assignAll(xsTemp); //65535
    xsDisplay.assignAll(xsDisplayTemp);
    int divX = Get.find<RangeWaveLengthController>().divX.value.toInt();
    int ii = 0;
    for (var i = 0; i < 2048; i++) {
      // final value = double.parse(
      //     (Random().nextInt(65535).toDouble() + 1).toStringAsFixed(2));
      final double value = (i * 0.56) + 190;
      xsTemp.add(value / divX);
      xsDisplayTemp.add(value);
      ii++;
      if (ii > 1024) break;
    }
    print('wltable ${xsTemp[0]}');
    xsTemp.removeAt(0);
    xsDisplayTemp.removeAt(0);
    print('wltable ${xsTemp[0]}');
    xs.assignAll(xsTemp); //65535
    xsDisplay.assignAll(xsDisplayTemp);

    List<FlSpot> y = []; //65535

    for (var i = 0; i < xs.length; i++) {
      y.add(FlSpot(xs[i], 0));
    }
    ys.assignAll(y);
    //print('now ${DateTime.now()}');
    //display.value = '${DateTime.now()} $testChannels';
    for (var i = 0; i < 5; i++) {
      List<double> rwlTemp = [];
      Get.find<RangeWaveLengthController>()
          .rwls[i]
          .value
          .tableX
          .assignAll(rwlTemp);
      Get.find<RangeWaveLengthController>()
          .rwls[i]
          .value
          .tableX
          .assignAll(xsDisplayTemp);

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
      //print('start end $start $end');
      Get.find<RangeWaveLengthController>().updateRange(
        Get.find<RangeWaveLengthController>().rwls[i],
        start: start, //double.parse('${allRows[0]["Value"]}'),
        end: end, //double.parse('${allRows[1]["Value"]}'),
      );
      // print(
      //     'tableX length : ${Get.find<RangeWaveLengthController>().rwls[i].value.tableX.length}');
      // Get.find<RangeWaveLengthController>().updateRV(
      //     Get.find<RangeWaveLengthController>().rwls[i],
      //     RangeValues(i.toDouble() * 200 + 150, i.toDouble() * 200 + 211));
      // print('init ${Get.find<RangeWaveLengthController>().rwls[i].value.rv}');
    }
    Get.find<RangeWaveLengthController>().rwls[0].value.color =
        Colors.red.shade300;
    Get.find<RangeWaveLengthController>().rwls[1].value.color =
        Colors.orange.shade300;
    Get.find<RangeWaveLengthController>().rwls[2].value.color =
        Colors.yellow.shade300;
    Get.find<RangeWaveLengthController>().rwls[3].value.color =
        Colors.green.shade300;
    Get.find<RangeWaveLengthController>().rwls[4].value.color =
        Colors.blue.shade300;
  }
//시뮬레이션데이터

//축 관련
  VerticalRangeAnnotation verticalRangeAnnotation(Rx<RangeWaveLength> rwl) {
    double x1 = 0.0;
    double x2 = 0.0;
    Color color = Colors.white;
    final int divX = Get.find<RangeWaveLengthController>().divX.value.toInt();
    if (rwl.value.visible) {
      x1 = rwl.value.vStart / divX;
      x2 = rwl.value.vEnd / divX;
      color = rwl.value.color;
    } else {}

    if (x2 - x1 == 0) {
      int idx = rwl.value.rv.end.toInt() + 1;
      if (idx >= rwl.value.tableX.length) idx = rwl.value.tableX.length - 1;
      if (idx < 0)
        x2 = 1;
      else
        x2 = rwl.value.tableX[idx] / divX;
    }
    return VerticalRangeAnnotation(
      x1: x1,
      x2: x2,
      color: color,
    );
  }
//축 관련

//복붙-그냥 토스트로 에러메시지 띄운거임
  _showToastError({required String msg}) {
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
      toastDuration: Duration(seconds: 5),
    );
  }

  _showToastInfo({required String msg}) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check),
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
      toastDuration: Duration(seconds: 5),
    );
  }

//복붙-걍 토스트로 에러메시지 띄운거임

//가상으로 데이터 넣어서 스타트해보기
  void _setRandomData() {
    Get.find<CountControllerWithReactive>().vpp.value =
        double.parse((Random().nextInt(2).toDouble() + 1).toStringAsFixed(2));
    Get.find<CountControllerWithReactive>().dpcr.value =
        Random().nextInt(100).toDouble();
  }

//가상으로 데이터 넣어서 스타트해보기

//<2번>퓨처는 어웨이트 만날때 까지 기다려야지..
//헤모스의 시리즈는
//어웨이트니까 1. 차트업데이트가 되고, 2.csv로 세이브가 되고,
//파장(rwl)과 값(v)이 업데이트 된다.
  Future<void> updateSeriesonlyHemos() async {
    Get.find<RangeWaveLengthController>()
        .updateValue(Get.find<RangeWaveLengthController>().rwls[0], 0.0);
    await Get.find<CountControllerWithReactive>().updateChart();
    if (Get.find<CountControllerWithReactive>().bFileSave.value)
      await Get.find<CountControllerWithReactive>().csvSave();
  }
//

  Future<void> updateSeries() async {
    //print('start ${DateTime.now()}');
    //print("updateSeries");
    Pointer<Int32> pv = calloc<Int32>(2250);
    if (spReadDataEx(pv, ch) < 0) {
      print('spReadDataEx fail');
    }
    List<FlSpot> y = []; //65535
    List<FlSpot> y10 = []; //65535
    List<double> yValues = []; //65535
    List<double> starts = [];
    List<double> ends = [];
    for (var i = 0;
        i < Get.find<RangeWaveLengthController>().rwls.length;
        i++) {
      starts.add(Get.find<RangeWaveLengthController>().rwls[i].value.rv.start);
      ends.add(Get.find<RangeWaveLengthController>().rwls[i].value.rv.end);
    }
    int cutValue = 1;
    int divY = Get.find<RangeWaveLengthController>().divY1.value.toInt();
    for (var i = 0; i < xs.length; i++) {
      y.add(FlSpot(xs[i], pv[i + cutValue].toDouble() * 1 / divY));
      y10.add(FlSpot(xs[i], pv[i + cutValue].toDouble() * 10 / divY));
      yValues.add(pv[i + cutValue].toDouble());
    }
    Get.find<RangeWaveLengthController>().yValues.assignAll(yValues);
    List<double> values = [];

    for (var i = 0; i < 5; i++) {
      int start =
          Get.find<RangeWaveLengthController>().rwls[i].value.rv.start.toInt();
      int end =
          Get.find<RangeWaveLengthController>().rwls[i].value.rv.end.toInt() +
              1;
      values.add(0.0);
      for (var ii = start; ii < end; ii++) {
        values[i] += pv[ii + cutValue].toDouble();
      }
      final value = values[i] / (end - start);
      Get.find<RangeWaveLengthController>()
          .updateValue(Get.find<RangeWaveLengthController>().rwls[i], value);
    }
    await Get.find<CountControllerWithReactive>().updateChart();
    if (Get.find<CountControllerWithReactive>().bFileSave.value)
      await Get.find<CountControllerWithReactive>().csvSave();
    displayMax.value = y.map((e) => e.y).reduce(max) * divY;
    //print('now ${DateTime.now()}');
    ys.assignAll(y);
    ys10.assignAll(y10);
    // for (var i = 0; i < 20; i++)
    //   print('wltable/pv ${f.length}/$i ${xs[i]}/${pv[i]} ${f[i].x}');
    calloc.free(pv);
    //Future.delayed(Duration(milliseconds: 20));
    //print('end ${DateTime.now()}');
  }

  Future<void> updateSeriesSimulation() async {
    //print('start ${DateTime.now()}');
    //print("updateSeries");

    List<FlSpot> y = []; //65535
    List<FlSpot> y10 = []; //65535
    List<double> yValues = []; //65535
    List<double> starts = [];
    List<double> ends = [];
    for (var i = 0;
        i < Get.find<RangeWaveLengthController>().rwls.length;
        i++) {
      starts.add(Get.find<RangeWaveLengthController>().rwls[i].value.rv.start);
      ends.add(Get.find<RangeWaveLengthController>().rwls[i].value.rv.end);
    }
    //int cutValue = 1;
    int divY = Get.find<RangeWaveLengthController>().divY1.value.toInt();
    for (var i = 0; i < xs.length; i++) {
      final value = Random().nextInt(65535).toDouble();
      y.add(FlSpot(xs[i], value * 1 / divY));
      y10.add(FlSpot(xs[i], value * 10 / divY));
      yValues.add(value);
    }
    Get.find<RangeWaveLengthController>().yValues.assignAll(yValues);
    List<double> values = [];

    for (var i = 0; i < 5; i++) {
      int start =
          Get.find<RangeWaveLengthController>().rwls[i].value.rv.start.toInt();
      int end =
          Get.find<RangeWaveLengthController>().rwls[i].value.rv.end.toInt() +
              1;
      values.add(0.0);
      for (var ii = start; ii < end; ii++) {
        values[i] += yValues[ii].toDouble();
      }
      final value = values[i] / (end - start);
      Get.find<RangeWaveLengthController>()
          .updateValue(Get.find<RangeWaveLengthController>().rwls[i], value);
    }
    await Get.find<CountControllerWithReactive>().updateChart();
    if (Get.find<CountControllerWithReactive>().bFileSave.value)
      await Get.find<CountControllerWithReactive>().csvSave();
    displayMax.value = y.map((e) => e.y).reduce(max) * divY;
    //print('now ${DateTime.now()}');
    ys.assignAll(y);
    ys10.assignAll(y10);
    // for (var i = 0; i < 20; i++)
    //   print('wltable/pv ${f.length}/$i ${xs[i]}/${pv[i]} ${f[i].x}');
    //Future.delayed(Duration(milliseconds: 20));
    //print('end ${DateTime.now()}');
  }

  Future<int> updateChart() async {
    if (ch < 0) return -1;
    // print("updateChart");
    // print("ch: $ch");
    if (spSetupGivenChannel(ch) < 0) {
      print('spSetupGivenChannel fail');
      return -1;
    }

    if (spInitGivenChannel(0, ch) < 0) {
      print('spGetAssignedChannelID fail');
    }

    final int integration =
        Get.find<CountControllerWithReactive>().config.value.integrationTime;
    print('integrationTime ${integration}');
    int rt = spSetIntEx(integration, ch);
    print('rtrtrt $rt');
    if (rt < 0) {
      print('spSetIntEx fail');
    }
    //if (_timer != null) if (_timer.isActive) return;
    //print('stemp ${Get.find<CountControllerWithReactive>().step.value * 1000}');
    _timerAll = Timer.periodic(
        Duration(
            milliseconds: Get.find<CountControllerWithReactive>()
                .config
                .value
                .intervalTime), (timer) async {
      //_setRandomData();
      //await updateSeries();
      await updateSeries();
      //timer.cancel();
    });
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors = [
      const Color(0xFFC41818),
      const Color(0xFFEE05C7),
      const Color(0xFFCBEE05)
    ];

    fToast = FToast();
    fToast.init(context);
    _timerAll.cancel();
    _timerHemos.cancel();
    // serialConnect = wgsFunction
    // .lookup<NativeFunction<Int32 Function(Int32)>>("serialConnect")
    // .asFunction();
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Row(children: [
        const SizedBox(width: 20),
        Obx(
          () => IgnorePointer(
            ignoring:
                Get.find<RangeWaveLengthController>().disabledButton.value,
            child: OutlinedButton(
                child: Text('스타트'),
                style: OutlinedButton.styleFrom(
                    primary: Get.find<RangeWaveLengthController>()
                            .disabledButton
                            .value
                        ? Colors.black
                        : Colors.green,
                    backgroundColor: Get.find<RangeWaveLengthController>()
                            .disabledButton
                            .value
                        ? Colors.grey
                        : Colors.white),
                onPressed: () async {
                  //
                  Get.find<RangeWaveLengthController>().disabledButton.value =
                      true;
                  Get.find<CountControllerWithReactive>().initchartX();
                  Get.find<CountControllerWithReactive>().xValue.value = 0;
                  Get.find<CountControllerWithReactive>()
                      .vppPoints
                      .assignAll([]);
                  Get.find<CountControllerWithReactive>()
                      .dpcrPoints
                      .assignAll([]);
                  Get.find<CountControllerWithReactive>().vpp.value = 0.0;
                  Get.find<CountControllerWithReactive>().dpcr.value = 0.0;
                  //
                  for (var i = 0;
                      i <
                          Get.find<CountControllerWithReactive>()
                              .oesPoints
                              .length;
                      i++) {
                    Get.find<CountControllerWithReactive>()
                        .oesPoints[i]
                        .assignAll([]);
                  }
                  String msg = '';
                  int rt = 0;
                  serialStart = true;

                  //<1번>스타트버튼 클릭하면, 버튼 비활성화, 헤모스 시리즈 들어옴.,
                  //callback은 주어진시간만큼 대기했다가, 호출되어지는 함수이다.
                  //헤모스 값 들어온 상태에서, oes값이 안들어 오면,(헤모스 값만 들어온 상태면,)
                  //헤모스값이 들어왔는데, 시리얼에 이미 뭔가있으면, 통신이상
                  if (Get.find<RangeWaveLengthController>().modeHemos.value) {
                    //await를 startSerial()!=0 앞에 붙여야 함.
                    //필요한데 잠깐 주석처리
                    // if (startSerial() != 0) {
                    // print('통신이상');
                    // msg = '헤모스 통신이상, com port확인';
                    // rt++;
                    // }
                    //필요한데 잠깐 주석처리
                    //<3번>oes값이 아닌게 들어오면, 헤모스 타이머 실시,
                    //컨피그 값중에  intervalTime설정한거대로 그 주기로 헤모스그래프를 그린다.
                    if (!Get.find<RangeWaveLengthController>().modeOES.value) {
                      _timerHemos = Timer.periodic(
                          Duration(
                              milliseconds:
                                  Get.find<CountControllerWithReactive>()
                                      .config
                                      .value
                                      .intervalTime), (timer) async {
                        _setRandomData();
                        // updateSeriesonlyHemos();
                      });
                    }
                  }
                  //<4번>oes값이 들어오면,
                  if (Get.find<RangeWaveLengthController>().modeOES.value) {
                    initSimulation();
                    _timerAll = Timer.periodic(
                        Duration(
                            milliseconds:
                                Get.find<CountControllerWithReactive>()
                                    .config
                                    .value
                                    .intervalTime), (timer) async {
                      await updateSeriesSimulation();
                      _setRandomData();
                    });
                    // init();
                    // await가 updateChart()!=0앞에와야하는데 에러나서 지움
                    //rt가 뭐지
                    // if (updateChart() != 0) {
                    // print('통신이상');
                    // if (rt > 0) msg += '/';
                    // msg = '분광기연결확인';
                    // rt++;
                    // }
                    //rt가 뭐지
                  } else {}
                  if (rt > 0) _showToastError(msg: msg);
                }),
          ),
        ),
        const SizedBox(width: 20),
        Obx(
          () => IgnorePointer(
            ignoring:
                !Get.find<RangeWaveLengthController>().disabledButton.value,
            child: OutlinedButton(
              child: Text('멈춤'),
              style: OutlinedButton.styleFrom(
                primary:
                    !Get.find<RangeWaveLengthController>().disabledButton.value
                        ? Colors.grey
                        : Colors.blue,
              ),
              onPressed: () {
                Get.find<RangeWaveLengthController>().disabledButton.value =
                    false;
                Get.find<RangeWaveLengthController>().disabledSave.value =
                    false;
                // if (port.isOpen) {
                //   port.close();
                //   port.dispose();
                // }
                serialStart = false;
                Get.find<CountControllerWithReactive>().bFileSave.value = false;
                _timerAll.cancel();
                _timerHemos.cancel();
                // print('timer ${_timer.isActive}');
              },
            ),
          ),
        ),
      ])
    ]);
  }
}
