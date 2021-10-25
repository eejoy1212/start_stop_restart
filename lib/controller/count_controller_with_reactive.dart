import 'dart:async';
import 'dart:io';

import "package:get/get.dart";
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:start_stop_restart/widget/range_wave_length.dart';

//복붙함
//import 'package:rs232/src/function/test.dart';

class Config {
  Config({
    required this.integrationTime,
    required this.intervalTime,
    required this.samplingTime,
    required this.waveLengthRanges,
    required this.serialPort,
    required this.modeHemos,
    required this.modeOES,
  });
  String serialPort;
  int integrationTime;
  int intervalTime;
  int samplingTime;
  int modeHemos;
  int modeOES;
  List<Map<String, dynamic>> waveLengthRanges;
  factory Config.init() {
    return Config(
      integrationTime: 0,
      intervalTime: 0,
      samplingTime: 0,
      waveLengthRanges: RxList.empty(),
      serialPort: "",
      modeHemos: 0,
      modeOES: 0,
    );
  }
}

class CountControllerWithReactive extends GetxController {
  static CountControllerWithReactive get to => Get.find();
  RxDouble vpp = 0.0.obs;
  RxDouble dpcr = 0.0.obs;
  //Rx<List<double>> sliderSE = <Double>[].obs;
  RxDouble sliderStart = 0.0.obs;
  RxDouble sliderEnd = 0.0.obs;
  RxList<FlSpot> vppPoints = RxList.empty();
  RxList<FlSpot> dpcrPoints = RxList.empty();
  RxList<RxList<FlSpot>> oesPoints = RxList.empty();
  Rx<Config> config = Config.init().obs;

  RxString pathOfTheFileToWrite = ''.obs;

  RxDouble xValue = 0.0.obs;
  //RxDouble step = 0.1.obs;
  RxBool bFileSave = false.obs;

  RxDouble chartMinX = 0.0.obs;
  RxDouble chartMaxX = 100.0.obs;
  final double chartX = 100.0;
  RxDouble limitlistBuffer = 1200.0.obs;
  RxBool hemosStop = false.obs;
  RxBool start = false.obs;
  //RxList<String> serialPort = [''].obs;
  RxList<String> serialPort = RxList.empty();
  RxString selectedPort = ''.obs;
  String a = 'a';
  //final timer = Timer.periodic(Duration(seconds: 1), (Timer t) => test());
  // void increase() {
  //   vpp = test();
  // }

  // void putNumber(int value) {
  //   count(value);
  // }

  @override
  void onInit() {
    //ever(selectedPort, (_) => print("매번 호출 $selectedPort"));
    // once(sliderStart, (_) => sliderStart = 1.0.obs);
    // once(sliderEnd, (_) => sliderEnd = 9.0.obs);
    // debounce(config.value.integrationTime, (_) {
    //   print("마지막 변경에 한번만 호출");
    // }, time: Duration(seconds: 3));
    // debounce(intervalTime, (_) => print("마지막 변경에 한번만 호출"),
    //     time: Duration(seconds: 1));

    // interval(count, (_) => print("변경되고 있는 동안 1초마다 호출"),
    //     time: Duration(seconds: 1));

    super.onInit();
  }

  void setSelected(String? value) {
    selectedPort.value = value!;
    //Get.find<CountControllerWithReactive>().config.value.serialPort = value!;
  }

  void updateConfig() {
    config.update((val) {
      if (val != null) {
        val.integrationTime =
            int.parse(val.waveLengthRanges[10]["Value"].toString());
        val.intervalTime =
            int.parse(val.waveLengthRanges[11]["Value"].toString());
        val.samplingTime =
            int.parse(val.waveLengthRanges[12]["Value"].toString());
        val.serialPort = val.waveLengthRanges[13]["Value"].toString();
        val.modeHemos = int.parse(val.waveLengthRanges[14]["Value"].toString());
        val.modeOES = int.parse(val.waveLengthRanges[15]["Value"].toString());
        //print("val.modeHemos ${val.modeHemos}");
        Get.find<RangeWaveLengthController>().modeHemos.value =
            val.modeHemos == 0 ? false : true;
        Get.find<RangeWaveLengthController>().modeOES.value =
            val.modeOES == 0 ? false : true;
        print(
            "Config ${val.integrationTime}, ${val.intervalTime}, ${val.samplingTime}, ${val.serialPort}, ${val.modeHemos}, ${val.modeOES}");
        if (serialPort.contains(val.serialPort))
          selectedPort.value = val.serialPort;
        else if (serialPort.length < 1)
          selectedPort.value = '-';
        else
          selectedPort.value = serialPort.first;
      } else
        print('CountControllerWithReactive updateConfig is null');
    });
  }

  void initchartX() {
    chartMinX.value = 0.0;
    chartMaxX.value = Get.find<CountControllerWithReactive>()
        .config
        .value
        .intervalTime
        .toDouble();
  }

  Future<void> updateChart() async {
    while (vppPoints.length > limitlistBuffer.value) {
      //limitlistBuffer.value) {
      if (Get.find<RangeWaveLengthController>().modeHemos.value) {
        vppPoints.removeAt(0);
        dpcrPoints.removeAt(0);
      }
      if (Get.find<RangeWaveLengthController>().modeOES.value) {
        for (var i = 0; i < oesPoints.length; i++) oesPoints[i].removeAt(0);
      }
    }
    final RxDouble step = (Get.find<CountControllerWithReactive>()
                .config
                .value
                .intervalTime
                .toDouble() /
            1000)
        .obs;
    if ((xValue.value) > (chartMaxX.value)) {
      chartMinX.value += step.value;
      chartMaxX.value += step.value;
    }
    if (Get.find<RangeWaveLengthController>().modeHemos.value) {
      vppPoints.add(FlSpot(xValue.value,
          vpp.value / Get.find<RangeWaveLengthController>().divY2.value));
      // print(
      //     'divYDPCR ${Get.find<RangeWaveLengthController>().divY2DPCR.value}');
      dpcrPoints.add(FlSpot(xValue.value,
          dpcr.value / Get.find<RangeWaveLengthController>().divY2DPCR.value));
    }
    if (Get.find<RangeWaveLengthController>().modeOES.value) {
      for (var i = 0; i < oesPoints.length; i++) {
        oesPoints[i].add(FlSpot(
            xValue.value,
            Get.find<RangeWaveLengthController>().rwls[i].value.value /
                Get.find<RangeWaveLengthController>().divY1.value));
      }
    }
    xValue.value += step.value;
  }

  Future<File> csvSave() async {
    //print("csv save in");

    DateTime current = DateTime.now();

    final String ms = DateTime.now().millisecondsSinceEpoch.toString();
    print("ms $ms");
    final int msLength = ms.length;
    print("msLength $msLength");
    final int zzz = int.parse(ms.substring(msLength - 3, msLength - 2));
    print("zzz $zzz");
    final String fileNameDate =
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(current)}.${zzz}';

    print('fileNameDate $fileNameDate');
    List<dynamic> hemosData = [];
    List<List<dynamic>> addHemosData = [];
    File file = File(pathOfTheFileToWrite.value);
    //print("file exists");
    hemosData.add(fileNameDate);

    if (Get.find<RangeWaveLengthController>().modeHemos.value) {
      hemosData.add(vpp.value);
      hemosData.add(dpcr.value);
    }
    if (Get.find<RangeWaveLengthController>().modeOES.value) {
      Get.find<RangeWaveLengthController>().rwls.forEach((e) {
        hemosData.add(e.value.value);
      });
      hemosData.addAll(Get.find<RangeWaveLengthController>().yValues);
    }

    addHemosData.add(hemosData);
    String csv = const ListToCsvConverter().convert(addHemosData) + '\n';
    //file.writeAsString(csv, mode: FileMode.append);

    //return;
    //File file = await File(pathOfTheFileToWrite);
    //print("Path $pathOfTheFileToWrite");
    //print("hemosData $hemosData");
    return file.writeAsString(csv, mode: FileMode.append);
  }

  Future<File> csvSaveInit() async {
    DateTime current = DateTime.now();
    print("csv save in");
    final String fileNameDate = DateFormat('yyyyMMdd_HHmmss').format(current);
    final String streamDateTime =
        DateFormat('yyyy/MM/dd HH:mm:ss.').format(current);
    //final directory = await getApplicationSupportDirectory();
    //pathOfTheFileToWrite.value = directory.path + "/$fileNameDate.csv";
    await Directory('datafiles').create();
    pathOfTheFileToWrite.value = "./datafiles/$fileNameDate.csv";
    String startTime = streamDateTime;
    File file = File(pathOfTheFileToWrite.value);

    //print("file no exists");
    String firstRow = "FileFormat:1";
    String secondRow = "HWType:SPdbUSBm";
    String thirdRow = "Start Time: $startTime";
    String fourthRowFirst = "Integration Time: ${config.value.integrationTime}";
    String fourthRowSecond = "Interval: ${config.value.intervalTime}";
    //String fourthRowThird = "Sampling Time: ${config.value.samplingTime}";
    print("exists in");
    String s =
        Get.find<RangeWaveLengthController>().rwls[0].value.tableX.join(',');
    List<String> ss = [];
    // print(
    //     'csvSave rwls length ${Get.find<RangeWaveLengthController>().rwls.length}');
    Get.find<RangeWaveLengthController>().rwls.forEach((e) {
      ss.add('${e.value.vStart}~${e.value.vEnd}');
    });
    String hemos = '';
    if (Get.find<RangeWaveLengthController>().modeHemos.value) {
      hemos = 'Vpp' + ',' + 'Dcpr' + ',';
    }
    String oes = '';
    if (Get.find<RangeWaveLengthController>().modeOES.value) {
      oes = ss.join(',') + ',' + s;
    }
    String intergrationColumn = firstRow +
        '\n' +
        secondRow +
        '\n' +
        thirdRow +
        '\n' +
        fourthRowFirst +
        ',' +
        fourthRowSecond +
        // ',' +
        // fourthRowThird +
        '\n' +
        "Time" +
        ',' +
        hemos +
        oes +
        '\n';

    // print("intergrationColumn \"n $intergrationColumn");
    // print("path ${pathOfTheFileToWrite.value}");
    return file.writeAsString(intergrationColumn);
  }
}
