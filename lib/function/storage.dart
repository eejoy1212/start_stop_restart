// import 'dart:async';
// import 'dart:io';
// import 'package:csv/csv.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

// class Storage {
//   Future<String> get _localPath async {
//     final directory = await getApplicationDocumentsDirectory();
//     print("directory $directory");
//     return directory.path;
//   }

//   Future<File> get _localFile async {
//     final path = await _localPath;
//     print("Path $path");
//     return File('$path/myCsvFile1.csv');
//   }

//   Future<double> readCounter() async {
//     try {
//       final file = await _localFile;
//       String contents = await file.readAsString();
//       return double.parse(contents);
//     } catch (e) {
//       // 에러가 발생할 경우 0을 반환
//       return 0;
//     }
//   }

//   Future<File> writeCounter(List<List<dynamic>> value) async {
//     final file = await _localFile;
//     String csv = const ListToCsvConverter().convert(value);
//     print("csv $csv");
//     return file.writeAsString(csv);
//   }
// }
