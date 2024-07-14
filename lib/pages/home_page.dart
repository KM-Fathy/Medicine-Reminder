import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/models/medicines_model.dart';
import 'package:medicine_reminder/Notification/flutter_local_notifications.dart';
import 'package:medicine_reminder/pages/add_medicine_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Medicine> medicines = [];
  List<bool> switchValues = [];
  List<bool> checkValues = [];
  List<Medicine> checkedMedicines = [];
  List<bool> temporaryLocks = [];
  bool isLocked = false;
  final GlobalKey _globalKey = GlobalKey();
  late Timer _midnightTimer;

  @override
  void initState() {
    super.initState();
    loadMedicines();
    _scheduleMidnightUpdate();
  }

  @override
  void dispose() {
    _midnightTimer.cancel();
    super.dispose();
  }

  void _scheduleMidnightUpdate() {
    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = midnight.difference(now);

    print('Scheduling midnight update in $timeUntilMidnight');

    _midnightTimer = Timer(timeUntilMidnight, _handleMidnightUpdate);
  }

  void _handleMidnightUpdate() {
    print('Midnight update triggered');
    setState(() {});

    // Reschedule the timer for the next midnight
    _scheduleMidnightUpdate();
  }

  Future<void> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final medicineList = prefs.getStringList('medicines');
    final checkedMedicineList = prefs.getStringList('checkedMedicines');
    final lockedStatus = prefs.getBool('isLocked') ?? false;
    final savedCheckValues = prefs.getStringList('checkValues');

    if (medicineList != null) {
      setState(() {
        medicines = medicineList
            .map((item) => Medicine.fromJson(jsonDecode(item)))
            .toList();
        switchValues = List<bool>.generate(medicines.length, (index) => true);
        checkValues =
            savedCheckValues?.map((value) => value == 'true').toList() ??
                List<bool>.generate(medicines.length, (index) => false);

        if (checkedMedicineList != null) {
          checkedMedicines = checkedMedicineList
              .map((item) => Medicine.fromJson(jsonDecode(item)))
              .toList();
        }

        temporaryLocks =
        List<bool>.generate(medicines.length, (index) => false);

        for (int i = 0; i < medicines.length; i++) {
          LocalNotificationService.showScheduledNotification(
              medicines[i].time, medicines[i].name);
        }
      });
    }

    setState(() {
      isLocked = lockedStatus;
    });
  }

  Future<void> saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final medicineList =
    medicines.map((medicine) => jsonEncode(medicine.toJson())).toList();
    await prefs.setStringList('medicines', medicineList);

    final checkedMedicineList = checkedMedicines
        .map((medicine) => jsonEncode(medicine.toJson()))
        .toList();
    await prefs.setStringList('checkedMedicines', checkedMedicineList);

    await prefs.setBool('isLocked', isLocked);

    final checkValuesAsString =
    checkValues.map((value) => value.toString()).toList();
    await prefs.setStringList('checkValues', checkValuesAsString);
  }

  String getCurrentDay() {
    return DateFormat('EEEE, MMMM d').format(DateTime.now());
  }

  Future<Uint8List> generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final currentDay = getCurrentDay();

    final fontData =
    await rootBundle.load('fonts/IBMPlexSansArabic-Regular.ttf');
    final arabicFont = pw.Font.ttf(fontData);

    final formattedMedicines = medicines.map((medicine) {
      final cureTime = medicine.time.format(context);
      final checkedTime = medicine.checkedTime != null
          ? DateFormat('h:mm a').format(DateTime.parse(medicine.checkedTime!))
          : 'Not checked';
      return {
        'name': medicine.name,
        'cureTime': cureTime,
        'checkedTime': checkedTime,
        'imagePath': medicine.imagePath,
      };
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              currentDay,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          ...formattedMedicines.map((medicine) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (medicine['imagePath'] != null)
                        pw.Container(
                          width: 110,
                          height: 122,
                          child: pw.Image(
                            pw.MemoryImage(
                                File(medicine['imagePath']!).readAsBytesSync()),
                            fit: pw.BoxFit.fill,
                          ),
                        ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Directionality(
                              textDirection: pw.TextDirection.rtl,
                              child: pw.Text(
                                medicine['name']!,
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green,
                                  font: arabicFont,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Cure Time: ${medicine['cureTime']}',
                              style: pw.TextStyle(
                                  font: arabicFont), // Use the Arabic font
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Checked Time: ${medicine['checkedTime']}',
                              style: pw.TextStyle(
                                  font: arabicFont), // Use the Arabic font
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey),
                ],
              ),
            );
          }).toList(),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> sharePdf(BuildContext context) async {
    final pdfBytes = await generatePdf(context);
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/medicine_reminder.pdf");
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Medicine Reminder PDF');
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => sharePdf(context),
          icon: const Icon(Icons.share, color: Colors.white),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            color: const Color(0xff201f1d),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(
                  isLocked ? 'Unlock' : 'Lock',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    isLocked = !isLocked;
                  });
                  saveMedicines();
                },
              ),
              PopupMenuItem(
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  setState(() {
                    checkValues =
                    List<bool>.generate(medicines.length, (index) => false);

                    for (int i = 0; i < medicines.length; i++) {
                      medicines[i].checkedTime = null;
                      temporaryLocks[i] = false;
                    }

                    checkedMedicines.clear();
                  });

                  Future.delayed(const Duration(milliseconds: 300), () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('checkedMedicines');
                    await prefs.remove('checkValues');
                    await prefs.remove('isLocked');
                  });

                  saveMedicines();
                },
              ),
            ],
          ),
        ],
        centerTitle: true,
        title: const Text(
          "Medicine Reminder",
          style:
          TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff201f1d),
      ),
      backgroundColor: const Color(0xff282724),
      body: RepaintBoundary(
        key: _globalKey,
        child: Column(
          children: [
            Container(
              width: screenWidth,
              padding: const EdgeInsets.all(10),
              color: const Color(0xff201f1d),
              child: Center(
                child: Text(
                  getCurrentDay(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ListView.builder(
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
                    final checkedTime = medicine.checkedTime != null
                        ? DateFormat('h:mm a')
                        .format(DateTime.parse(medicine.checkedTime!))
                        : 'Not checked';
                    return GestureDetector(
                      onTap: isLocked || temporaryLocks[index]
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddMedicine(medicine: medicines[index]),
                          ),
                        ).then((result) {
                          if (result != null && result is Medicine) {
                            setState(() {
                              medicines[index] = result;
                              LocalNotificationService
                                  .showScheduledNotification(
                                  result.time, result.name);
                            });
                            saveMedicines();
                          }
                        });
                      },
                      child: Card(
                        elevation: 0,
                        color: const Color(0xff201f1d),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (medicine.imagePath != null)
                                    SizedBox(
                                      width: screenWidth * 0.3,
                                      height: screenHeight * 0.19,
                                      child: Image.file(
                                        File(medicine.imagePath!),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: screenHeight * 0.15,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.start,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              medicine.name,
                                              style: const TextStyle(
                                                  color: Colors.lightGreen,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Cure Time: ${medicine.time.format(context)}',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Checked Time: $checkedTime',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.start,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Switch(
                                        value: switchValues[index],
                                        onChanged: (val) {
                                          setState(() {
                                            switchValues[index] = val;
                                          });
                                          if (val) {
                                            LocalNotificationService
                                                .showScheduledNotification(
                                                medicine.time,
                                                medicine.name);
                                          } else {
                                            LocalNotificationService
                                                .cancelNotification(
                                                LocalNotificationService
                                                    .notificationIds(
                                                    medicine.name));
                                          }
                                        },
                                        activeColor: Colors.white,
                                        activeTrackColor: Colors.lightGreen,
                                      ),
                                      Checkbox(
                                        value: checkValues[index],
                                        onChanged: temporaryLocks[index]
                                            ? null
                                            : (value) async {
                                          setState(() {
                                            checkValues[index] =
                                                value ?? false;
                                            if (value ?? false) {
                                              temporaryLocks[index] = true;
                                              Future.delayed(
                                                  const Duration(
                                                      seconds: 30),
                                                      () {
                                                    setState(() {
                                                      medicines[index]
                                                          .checkedTime =
                                                          DateTime.now()
                                                              .toString();
                                                      checkedMedicines
                                                          .add(medicine);
                                                      temporaryLocks[index] =
                                                      false;
                                                      saveMedicines();
                                                    });
                                                  });
                                            } else {
                                              medicines[index]
                                                  .checkedTime = null;
                                              checkedMedicines
                                                  .remove(medicine);
                                              saveMedicines();
                                            }
                                          });
                                        },
                                        checkColor: Colors.white,
                                        side: const BorderSide(
                                            color: Colors.white),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.delete,
                                            color: Colors.white),
                                        onPressed: temporaryLocks[index]
                                            ? null
                                            : () {
                                          LocalNotificationService
                                              .cancelNotification(
                                              LocalNotificationService
                                                  .notificationIds(
                                                  medicine.name));
                                          setState(() {
                                            checkValues
                                                .removeAt(index);
                                            switchValues
                                                .removeAt(index);
                                            medicines.removeAt(index);
                                            temporaryLocks.removeAt(index);
                                          });
                                          saveMedicines();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.lightGreen,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicine()),
          ).then((result) {
            if (result != null && result is Medicine) {
              setState(() {
                medicines.add(result);
                switchValues.add(true);
                checkValues.add(false);
                temporaryLocks.add(false);
                LocalNotificationService.showScheduledNotification(
                    result.time, result.name);
              });
              saveMedicines();
            }
          });
        },
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}
