// import 'package:libserialport/libserialport.dart';
// import 'package:flutter_libserialport/flutter_libserialport.dart';
// //

// void test() {
//   final port = SerialPort("COM1");
//   port.config.baudRate = 115200;
//   if (!port.openReadWrite()) {
//     print(SerialPort.lastError);
//   }
//   final reader = SerialPortReader(port);
//   reader.stream.listen((data) {
//     List<int> nums = [];
//     // for (int i = 0; i < 13; i++) {
//     //   nums.add(Random().nextInt(10) + 48);
//     // }
//     //print('nums $nums');
//     data[1] = nums[1]; //id

//     data[2] = nums[2];
//     data[3] = nums[3];
//     data[5] = nums[5];
//     data[6] = nums[6];
//     data[7] = nums[7];

//     data[8] = nums[8];
//     data[9] = nums[9];
//     data[11] = nums[11];
//     if (data[0] != 2) return;
//     if (data[4] != 46) return;
//     String stx = String.fromCharCodes([data[0]]);

//     String _id = String.fromCharCodes([data[1]]);
//     int id = int.parse(_id);

//     String _Vpp_int_first = String.fromCharCodes([data[2]]);
//     String _Vpp_int_second = String.fromCharCodes([data[3]]);
//     String _Vpp_float_first = String.fromCharCodes([data[5]]);
//     String _Vpp_float_second = String.fromCharCodes([data[6]]);
//     String _Vpp_float_third = String.fromCharCodes([data[7]]);

//     String _Dpcr_int_first = String.fromCharCodes([data[8]]);
//     String _Dpcr_int_second = String.fromCharCodes([data[9]]);
//     String _Dpcr_float_first = String.fromCharCodes([data[11]]);

//     String etx = String.fromCharCodes([data[12]]);

//     double vpp = double.parse(_Vpp_int_first +
//         _Vpp_int_second +
//         '.' +
//         _Vpp_float_first +
//         _Vpp_float_second +
//         _Vpp_float_third);

//     double dpcr = double.parse(
//         _Dpcr_int_first + _Dpcr_int_second + '.' + _Dpcr_float_first);
//     //get.find<CountControllerWithReactive>().vpp.value = vpp;
//     //get.find<CountControllerWithReactive>().dpcr.value = dpcr;
//     print('stx: $stx $id $vpp $dpcr $etx');
//   });
// }
