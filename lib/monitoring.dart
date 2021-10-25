import 'dart:async';
import 'dart:ffi';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:start_stop_restart/controller/count_controller_with_reactive.dart';
import 'package:start_stop_restart/widget/range_wave_length.dart';
import 'package:toggle_switch/toggle_switch.dart';

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
  //SerialPort port = SerialPort('');
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
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Row(
        children: [
          const SizedBox(width: 20),
          Obx(
            () => IgnorePointer(
              ignoring:
                  Get.find<RangeWaveLengthController>().disabledButton.value,
              child: ToggleSwitch(
                minWidth: 90,
                cornerRadius: 20.0,
                activeBgColors: [
                  [Colors.green[800]!],
                  [Colors.red[800]!]
                ],
                activeFgColor:
                    Get.find<RangeWaveLengthController>().disabledButton.value
                        ? Colors.black
                        : Colors.white,
                inactiveBgColor: Colors.grey,
                inactiveFgColor: Colors.black,
                initialLabelIndex: 1,
                totalSwitches: 2,
                labels: ['Start', 'Stop'],
                radiusStyle: true,
                onToggle: (index) async{
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
                  print('switched to: $index');
                },
              ),
            ),
          ),
        ],
      ),
    ]);
  }
}
