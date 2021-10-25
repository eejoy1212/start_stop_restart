import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RangeWaveLengthController extends GetxController {
  RxList<Rx<RangeWaveLength>> rwls = RxList.empty();
  RxList<double> yValues = RxList.empty();
  RxBool vppVisible = true.obs;
  RxBool dpcrVisible = true.obs;
  RxBool modeHemos = true.obs;
  RxBool modeOES = true.obs;
  RxDouble divX = 100.0.obs;
  RxDouble divY1 = 10000.0.obs;
  RxDouble divY2 = 0.5.obs;
  RxDouble divY2DPCR = ((100 / 3.3) * 0.5).obs;
  RxBool disabledButton = false.obs;
  RxBool disabledSave = false.obs;
  // RxBool endButton = false.obs;
  // RxBool configStop = true.obs;
  // Future<void> updateRealChart() async {
  //   while (rwls[0].length > limitCount) {
  //     for (var i = 0; i < rwls.length; i++) {
  //       rwls[i].value.rvs.removeAt(0);
  //     }
  //   }
  //   // double a = xValue;
  //   // double b = controller.vpp.value;
  //   for (var i = 0; i < rwls.length; i++) {
  //     rwls[i].value.add(FlSpot(xValue, controller.vpp.value));
  //   }

  //   dcprPoints.add(FlSpot(xValue, controller.dcpr.value));
  //   xValue += step;
  // }

  void updateValue(Rx<RangeWaveLength> rwl, double v) {
    rwl.update((val) {
      if (val != null) {
        val.value = v.round().toDouble();
      } else
        print('RangeWaveLengthController updateValue is null');
    });
  }

  void updateRV(Rx<RangeWaveLength> rwl, RangeValues rv) {
    rwl.update((val) {
      if (val != null) {
        val.rv = rv;
        val.vStart = val.tableX[rv.start.round()];
        val.vEnd = val.tableX[rv.end.round()];
      } else
        print('RangeWaveLengthController updateRV is null');
    });
  }

  void updateRange(Rx<RangeWaveLength> rwl, {start, end}) {
    rwl.update((val) {
      if (val != null) {
        if (val.tableX.length < 1) return;
        val.vStart = val.tableX[start.round()];
        val.vEnd = val.tableX[end.round()];
        // print('updateRange4 $start, $end');
        val.rv = RangeValues(start, end);
        // print('updateRange4');
      } else
        print('RangeWaveLengthController updateRange is null');
    });
  }

  void updateVIsibleChk(Rx<RangeWaveLength> rwl, {required chkVisible}) {
    rwl.update((val) {
      if (val != null) val.visible = chkVisible;
    });
  }
}

class RangeWaveLength {
  RangeWaveLength({
    required this.rv,
    required this.vStart,
    required this.vEnd,
    required this.tableX,
    required this.visible,
    required this.color,
    required this.value,
  });

  RangeValues rv;
  double vStart;
  double vEnd;
  List<double> tableX;
  bool visible;
  Color color;
  double value;

  factory RangeWaveLength.init() {
    return RangeWaveLength(
      rv: RangeValues(0, 0),
      vStart: 0.0,
      vEnd: 0.0,
      tableX: [],
      visible: true,
      color: Colors.white,
      value: 0.0,
    );
  }
}

// ignore: must_be_immutable
class RangeWaveLengthWidget extends StatelessWidget {
  RangeWaveLengthWidget({Key? key, required this.rwl}) : super(key: key);
  Rx<RangeWaveLength> rwl; // = RangeWaveLength.init().obs;
  void setRangeValues(start, end) {
    if (start < 0) return;
    if (start > end) return;
    if (end > rwl.value.tableX.length - 1) return;

    Get.find<RangeWaveLengthController>()
        .updateRV(rwl, RangeValues(start, end));

    print('setRangeValues before $start $end');
    print('setRangeValues after ${rwl.value.rv.start} ${rwl.value.rv.end}');
  }

  @override
  Widget build(BuildContext context) {
    double dFontSize = 10.0;
    //currentRangeValues = Get.find<RangeWaveLengthController>().rvm.value.rv;
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(right: 15, left: 15, top: 1, bottom: 1),
        child: Container(
          height: 100,
          child: Column(children: [
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Checkbox(
                      value: rwl.value.visible,
                      onChanged: (value) {
                        if (value != null)
                          Get.find<RangeWaveLengthController>()
                              .updateVIsibleChk(rwl, chkVisible: value);
                      }),
                  Text('Start', style: TextStyle(fontSize: dFontSize)),
                  IgnorePointer(
                    ignoring: Get.find<RangeWaveLengthController>()
                        .disabledButton
                        .value,
                    child: IconButton(
                        onPressed: () {
                          setRangeValues(
                              rwl.value.rv.start - 1, rwl.value.rv.end);
                        },
                        icon: Icon(Icons.remove,
                            color: Get.find<RangeWaveLengthController>()
                                    .disabledButton
                                    .value
                                ? Colors.grey
                                : Colors.blue)),
                  ),
                  rwl.value.tableX.length == 0
                      ? Container()
                      : Text(
                          rwl.value.tableX[rwl.value.rv.start.toInt()]
                              .toStringAsFixed(2),
                          style: TextStyle(fontSize: dFontSize)),
                  IgnorePointer(
                    ignoring: Get.find<RangeWaveLengthController>()
                        .disabledButton
                        .value,
                    child: IconButton(
                      onPressed: () {
                        setRangeValues(
                            rwl.value.rv.start + 1, rwl.value.rv.end);
                      },
                      icon: Icon(Icons.add,
                          color: Get.find<RangeWaveLengthController>()
                                  .disabledButton
                                  .value
                              ? Colors.grey
                              : Colors.blue),
                    ),
                  ),
                  SizedBox(width: 50),
                  Text('End', style: TextStyle(fontSize: dFontSize)),
                  IgnorePointer(
                    ignoring: Get.find<RangeWaveLengthController>()
                        .disabledButton
                        .value,
                    child: IconButton(
                        onPressed: () {
                          setRangeValues(
                              rwl.value.rv.start, rwl.value.rv.end - 1);
                        },
                        icon: Icon(Icons.remove,
                            color: Get.find<RangeWaveLengthController>()
                                    .disabledButton
                                    .value
                                ? Colors.grey
                                : Colors.blue)),
                  ),
                  rwl.value.tableX.length == 0
                      ? Container()
                      : Text(
                          rwl.value.tableX[rwl.value.rv.end.toInt()]
                              .toStringAsFixed(2),
                          style: TextStyle(fontSize: dFontSize)),
                  IgnorePointer(
                    ignoring: Get.find<RangeWaveLengthController>()
                        .disabledButton
                        .value,
                    child: IconButton(
                        onPressed: () {
                          setRangeValues(
                              rwl.value.rv.start, rwl.value.rv.end + 1);
                        },
                        icon: Icon(Icons.add,
                            color: Get.find<RangeWaveLengthController>()
                                    .disabledButton
                                    .value
                                ? Colors.grey
                                : Colors.blue)),
                  ),
                ],
              ),
            ),
            Container(
              child: Obx(
                () => IgnorePointer(
                  ignoring: Get.find<RangeWaveLengthController>()
                      .disabledButton
                      .value,
                  child: SliderTheme(
                    data: SliderThemeData(
                      inactiveTrackColor: Colors.grey,
                      thumbColor: Get.find<RangeWaveLengthController>()
                              .disabledButton
                              .value
                          ? Colors.grey
                          : Colors.blue,
                      overlayColor: Colors.blue,
                      valueIndicatorColor: Colors.blue,

                      // ,
                    ),
                    child: RangeSlider(
                      activeColor: Get.find<RangeWaveLengthController>()
                              .disabledButton
                              .value
                          ? Colors.grey
                          : Colors.blue,
                      onChanged: (d) {
                        rwl.value.rv = d;
                        print('onchanged ${rwl.value.tableX.length} $d');

                        // start = values[d.start.round()].toStringAsFixed(2);
                        // end = values[d.end.round()].toStringAsFixed(2);
                        try {
                          Get.find<RangeWaveLengthController>().updateRange(
                            rwl,
                            start: d.start,
                            end: d.end,
                          );
                          // Get.find<RangeWaveLengthController>().rvm.value.start =
                          //     values[d.start.round()].toStringAsFixed(2);
                          // Get.find<RangeWaveLengthController>().rvm.value.end =
                          //     values[d.end.round()].toStringAsFixed(2);
                        } catch (e) {
                          print('RangeSlider onChanged fail $e');
                        }
                      },
                      values: rwl.value.tableX.length != 0
                          ? rwl.value.rv
                          : RangeValues(0, 0),
                      min: 0,
                      max: rwl.value.tableX.length != 0
                          ? rwl.value.tableX.length - 1
                          : 1,
                      divisions: rwl.value.tableX.length != 0
                          ? rwl.value.tableX.length - 1
                          : 1,
                      labels: RangeLabels(rwl.value.vStart.toStringAsFixed(3),
                          rwl.value.vEnd.toStringAsFixed(3)
                          // _currentRangeValues.value.start.round().toString(),
                          // _currentRangeValues.value.end.round().toString(),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [],
            ),
          ]),
        ),
      ),
    );
  }
}
