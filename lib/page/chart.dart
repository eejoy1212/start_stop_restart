import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:start_stop_restart/controller/count_controller_with_reactive.dart';
import 'package:flutter/material.dart';
import 'package:start_stop_restart/widget/range_wave_length.dart';

class ChartPage extends GetView<CountControllerWithReactive> {
  ChartPage({Key? key}) : super(key: key);

  int integrationTime = 20;
  int intervalTime = 100;
  int sampleingTime = 50;
  double xValue = 0;
  double step = 0.1;
  double limitCount = 1000;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Obx(
                () => AspectRatio(
                  aspectRatio:
                      Get.find<RangeWaveLengthController>().modeOES.value
                          ? 4.2
                          : 2.1,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(18),
                      ),
                      color: Color(0xFFF0F5FA),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 18.0,
                        left: 12.0,
                        top: 24,
                        bottom: 12,
                      ),
                      child: LineChart(
                        mainData(),
                        swapAnimationDuration: Duration.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData mainData() {
    final hemos = Get.find<RangeWaveLengthController>().modeHemos.value;
    final oes = Get.find<RangeWaveLengthController>().modeOES.value;
    return LineChartData(
      minY: 0,
      maxY: 3.3 / Get.find<RangeWaveLengthController>().divY2.value,
      minX: controller.chartMinX.value,
      maxX: controller.chartMaxX.value,
      // minX: vppPoints.length < 1 ? 0 : vppPoints.first.x,
      // maxX: vppPoints.length < 1 ? 10 : vppPoints.last.x,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              List<LineTooltipItem?> l = [];

              for (var i = 0; i < touchedBarSpots.length; i++) {
                final textstyle = TextStyle(
                  color: touchedBarSpots[i].bar.colors[0],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
                String str = '';

                String y;
                if (touchedBarSpots[i].barIndex > 1)
                  y = (touchedBarSpots[i].y *
                          Get.find<RangeWaveLengthController>().divY1.value)
                      .toStringAsFixed(0);
                else if (touchedBarSpots[i].barIndex == 1)
                  y = (touchedBarSpots[i].y *
                          Get.find<RangeWaveLengthController>().divY2DPCR.value)
                      .toStringAsFixed(2);
                else
                  y = (touchedBarSpots[i].y *
                          Get.find<RangeWaveLengthController>().divY2.value)
                      .toStringAsFixed(2);

                if (i == 0)
                  str = '${touchedBarSpots[i].x.toStringAsFixed(1)}s \n $y';
                else
                  str = y;

                l.add(LineTooltipItem(str, textstyle));
              }
              return l;
            }),
      ),
      // touchTooltipData: ,
      clipData: FlClipData.all(),
      gridData: FlGridData(
        // drawVerticalLine: true, // x축 눈금표
        // drawHorizontalLine: true, // x축 눈금표
        //show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.black12,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.black12,
            strokeWidth: 1,
          );
        },
      ),
      lineBarsData: [
        if (Get.find<RangeWaveLengthController>().vppVisible.value)
          sinLine(controller.vppPoints),
        if (Get.find<RangeWaveLengthController>().dpcrVisible.value)
          cosLine(controller.dpcrPoints),
        if (Get.find<RangeWaveLengthController>().rwls[0].value.visible)
          lineChartBarData(controller.oesPoints[0],
              Get.find<RangeWaveLengthController>().rwls[0]),
        if (Get.find<RangeWaveLengthController>().rwls[1].value.visible)
          lineChartBarData(controller.oesPoints[1],
              Get.find<RangeWaveLengthController>().rwls[1]),
        if (Get.find<RangeWaveLengthController>().rwls[2].value.visible)
          lineChartBarData(controller.oesPoints[2],
              Get.find<RangeWaveLengthController>().rwls[2]),
        if (Get.find<RangeWaveLengthController>().rwls[3].value.visible)
          lineChartBarData(controller.oesPoints[3],
              Get.find<RangeWaveLengthController>().rwls[3]),
        if (Get.find<RangeWaveLengthController>().rwls[4].value.visible)
          lineChartBarData(controller.oesPoints[4],
              Get.find<RangeWaveLengthController>().rwls[4]),
      ],
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(
          showTitles: false,
          margin: 12,
        ),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 10,
          getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16),
          getTitles: (value) {
            return '${value.round()} s';
          },
          margin: 8,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {
            String xValue = '';

            switch (value.toInt()) {
              case 1:
                return oes && hemos
                    ? '10k\n0.5V / 15%'
                    : oes && !hemos
                        ? '10k'
                        : !oes && hemos
                            ? '0.5V / 15%'
                            : '';
              case 3:
                return oes && hemos
                    ? '30k\n1.5V / 45%'
                    : oes && !hemos
                        ? '30k'
                        : !oes && hemos
                            ? '1.5V / 45%'
                            : '';
              case 5:
                return oes && hemos
                    ? '50k\n2.5V / 75%'
                    : oes && !hemos
                        ? '50k'
                        : !oes && hemos
                            ? '2.5V / 75%'
                            : '';
            }
            return '';
          },
          reservedSize: 80,
          margin: 12,
        ),
      ),
    );
  }

  LineChartBarData sinLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      //colors: [sinColor.withOpacity(0), sinColor],
      colorStops: [0.1, 1.0],
      barWidth: 1,
      isCurved: false,
      colors: [Colors.black],
    );
  }

  LineChartBarData cosLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      //colors: [cosColor.withOpacity(0), cosColor],
      colorStops: [0.1, 1.0],
      barWidth: 1,
      isCurved: false,
      colors: [Colors.grey[500]!],
    );
  }

  LineChartBarData lineChartBarData(
      List<FlSpot> points, Rx<RangeWaveLength> rwl) {
    return LineChartBarData(
        spots: points,
        dotData: FlDotData(
          show: false,
        ),
        //colors: [cosColor.withOpacity(0), cosColor],
        colorStops: [0.1, 1.0],
        barWidth: 1,
        isCurved: true,
        colors: [rwl.value.color]
        //color: rwl.value.color,
        );
  }
}
