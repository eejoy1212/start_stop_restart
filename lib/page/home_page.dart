import 'dart:math';

import 'package:flutter/material.dart';
import 'package:start_stop_restart/monitoring.dart';
import 'package:start_stop_restart/page/chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
