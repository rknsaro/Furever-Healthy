// lib/my_pets/recent_notes.dart
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class RecentNotesPage extends StatefulWidget {
  const RecentNotesPage({super.key});

  @override
  State<RecentNotesPage> createState() => _RecentNotesPageState();
}

class _RecentNotesPageState extends State<RecentNotesPage> {
  String _noteType = 'General';
  String _activityType = 'Walk';
  final TextEditingController _noteController = TextEditingController();

  final List<String> noteTypes = ['General', 'Activity', 'Vet Appointment'];
  final List<String> activityTypes = ['Walk', 'Run', 'Food', 'Water'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        backgroundColor: _mint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Furever Healthy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications, color: Colors.white),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tabs Section (Profile / Appointments / Reminders)
            Container(
              color: _mint,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Appointments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Reminders", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Rounded white section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    "Note",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Note Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Note Type",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      DropdownButton<String>(
                        value: _noteType,
                        dropdownColor: Colors.white,
                        underline: Container(),
                        items: noteTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _mint.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  color: _mint,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _noteType = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Activity Type (only shows when Activity is selected)
                  if (_noteType == 'Activity') ...[
                    const Text(
                      "Activity Type",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _activityType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _mint),
                        ),
                      ),
                      items: activityTypes.map((act) {
                        return DropdownMenuItem<String>(
                          value: act,
                          child: Text(act),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _activityType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Text box for note
                  TextField(
                    controller: _noteController,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: "Write your note here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Select Pet Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text("Select Pets"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Date and Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Date", style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Text("30 Oct 2025"),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Time", style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Text("6:00 PM"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text("Add"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
