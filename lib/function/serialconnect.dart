import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:libserialport/libserialport.dart';
//import 'package:flutter_libserialport/flutter_libserialport.dart';

List<List<String>> wgsSplit(String s, String s1, String s2) {
  List<List<String>> rt = [];
  rt.add([]);
  rt.add([]);

  while (true) {
    final int end = s.indexOf(s1);
    if (end < 0) break;
    final int start = end - 3;
    final String dpcr = s.substring(start, end);
    s = s.replaceFirst(dpcr + '.', '');
    rt[0].add(dpcr);
  }
  if (s.length != 0) {
    if (s.lastIndexOf(s2) == s.length - 1) {
      s = s.replaceRange(s.length - 1, s.length, '');
    }
  }
  rt[1] = s.split(s2);
  return rt;
}

void serialPort() {
  print("serial");
  String a = "COM1";
  final port = SerialPort(a);
  print("port $port");
  port.config.baudRate = 115200;
  print('serial status1 ${port.isOpen}');
  if (!port.openRead()) {
    print("open error");
    print(SerialPort.lastError);
    return;
  }

  print("reader");
  final reader = SerialPortReader(port);
  print('${port.isOpen}');
  // print('${port.close()}');
  print('${port.isOpen}');
  int nCnt = 0;
  reader.stream.listen((data) {
    //if (Get.find<CountControllerWithReactive>().hemosStop.value) return;
    try {
      print("data ${data.length}");
      print("data $data");
      // List<int> list = 'someData'.codeUnits;
      print("listen");
      if (data[3] != 44 && data[3] != 46) {
        print("Invalid data entered");
        return;
      }

      Uint8List bytes = Uint8List.fromList(data);
      String s = String.fromCharCodes(bytes);

      List<List<String>> ss = wgsSplit(s, '.', ',');
      if (s.indexOf('.') > 0) {
        print('=======================================');
        print('시간${DateTime.now()} $nCnt');
        nCnt = 0;
        // port.close();
      }

      // print('s $s');
      // print('dpcr ${ss[0]}');
      // print('vpp ${ss[1]}');
      // if (s.indexOf('.') > 0) print('=======================================');
      nCnt += ss[1].length;
    } catch (e) {
      print('문제발생');
      port.close();
    }
    return;
    String stx = String.fromCharCodes([data[0]]);
    String _id = String.fromCharCodes([data[1]]);
    int id = int.parse(_id);
    String _Vpp_int_first = String.fromCharCodes([data[2]]);
    String _Vpp_int_second = String.fromCharCodes([data[3]]);
    String first_comma = String.fromCharCodes([data[4]]);
    String _Vpp_float_first = String.fromCharCodes([data[5]]);
    String _Vpp_float_second = String.fromCharCodes([data[6]]);
    String _Vpp_float_third = String.fromCharCodes([data[7]]);
    String _Dpcr_int_first = String.fromCharCodes([data[8]]);
    String _Dpcr_int_second = String.fromCharCodes([data[9]]);
    String second_comma = String.fromCharCodes([data[10]]);
    String _Dpcr_float_first = String.fromCharCodes([data[11]]);
    String etx = String.fromCharCodes([data[12]]);

    double vpp = double.parse(_Vpp_int_first +
        _Vpp_int_second +
        '.' +
        _Vpp_float_first +
        _Vpp_float_second +
        _Vpp_float_third);
    double dpcr = double.parse(
        _Dpcr_int_first + _Dpcr_int_second + '.' + _Dpcr_float_first);
    print('stx: $stx $id $vpp $dpcr $etx');
    //print('dpcr $dpcr');
    // print('id: $id');
    // print('dpcr: $dpcr');
    // print('etx: $etx');

    // int Vpp_int = 10 * data[2] + data[3];
    // int frist_Comma = data[4];
    // double Vpp_float =
    //     data[5] * 0.1 + data[6] * 0.01 + data[7] * 0.001;
    // int Dpcr_int = 10 * data[8] + data[9];
    // int second_Comma = data[10];
    // double Dpcr_float = data[11] * 0.1;
    // int etx = data[12];

    // //String stx = String.fromCharCodes(data);
    // print('stx: $stx');
    // print('id: $id');
    // print('Vpp_int: $Vpp_int');
    // print('frist_Comma: $frist_Comma');
    // print('Vpp_float: $Vpp_float');
    // print('Dpcr_int: $Dpcr_int');
    // print('second_Comma: $second_Comma');
    // print('Dpcr_float: $Dpcr_float');
    // print('Dpcr_float: $etx');
    //print('received: $f');
  });
}
