import 'package:flutter/material.dart';
import 'package:medicine_reminder/Notification/flutter_local_notifications.dart';
import 'package:medicine_reminder/models/medicines_model.dart';
import 'package:image_picker/image_picker.dart';

class AddMedicine extends StatefulWidget {
  final Medicine? medicine;

  const AddMedicine({Key? key, this.medicine}) : super(key: key);

  @override
  State<AddMedicine> createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  TextEditingController nameController = TextEditingController();
  TimeOfDay? selectedTime;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      nameController.text = widget.medicine!.name;
      selectedTime = widget.medicine!.time;
      imagePath = widget.medicine!.imagePath;
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        imagePath = pickedImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff201f1d),
        title: const Text(
          "Add Medicine",
          style:
          TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xff282724),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 200, left: 20, right: 20),
          child: Column(
            children: [
              TextField(
                cursorColor: Colors.lightGreen,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                controller: nameController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightGreen),
                  ),
                  labelText: "Medicine name",
                  labelStyle: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _selectImage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(400, 60),
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
                child: Text(
                  imagePath == null ? 'Select Image' : 'Image Selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  selectTime(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(400, 60),
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
                child: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : 'Time: ${selectedTime!.format(context)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty &&
                          selectedTime != null &&
                          imagePath != null) { // Check if image is selected
                        if (widget.medicine != null &&
                            (widget.medicine!.name != nameController.text ||
                                widget.medicine!.time != selectedTime)) {
                          LocalNotificationService.cancelNotification(
                              LocalNotificationService.notificationIds(
                                  widget.medicine!.name));
                        }
                        Medicine medicine = Medicine(
                          name: nameController.text,
                          time: selectedTime!,
                          imagePath: imagePath,
                        );
                        Navigator.pop(context, medicine);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 40),
                      backgroundColor: Colors.lightGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Set Reminder",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void selectTime(BuildContext context) {
    showTimePicker(
      barrierColor: const Color(0xff282724),
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((pickedTime) {
      if (pickedTime != null && pickedTime != selectedTime) {
        setState(() {
          selectedTime = pickedTime;
        });
      }
    });
  }
}