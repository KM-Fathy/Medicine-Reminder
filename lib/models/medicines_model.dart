import 'package:flutter/material.dart';

class Medicine {
  final String name;
  final TimeOfDay time;
  String? checkedTime;
  String? imagePath;

  Medicine({required this.name, required this.time, this.checkedTime, this.imagePath});

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      time: TimeOfDay(
        hour: json['hour'],
        minute: json['minute'],
      ),
      checkedTime: json['checkedTime'],
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hour': time.hour,
      'minute': time.minute,
      'checkedTime': checkedTime,
      'imagePath': imagePath,
    };
  }
}
