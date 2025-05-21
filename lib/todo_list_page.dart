import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'dart:convert'; // For JSON encoding/decoding

// Represents a single reminder (using Contact-like structure)
class Reminder {
  final String title;
  final String description;

  Reminder(this.title, this.description);

  // Convert a Reminder object to a JSON map
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
  };

  // Create a Reminder object from a JSON map
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      json['title'] as String,
      json['description'] as String,
    );
  }
}

// The main StatefulWidget for the Reminders application
class toDolist extends StatefulWidget {
  const toDolist({super.key});

  @override
  State<toDolist> createState() => _toDolistState();
}

// The State class for the toDolist widget, managing the reminder list and UI logic
class _toDolistState extends State<toDolist> {
  // Controllers for the text input fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // The list to store Reminder objects
  final List<Reminder> _reminders = []; // Renamed from _contacts for clarity

  late SharedPreferences _prefs; // SharedPreferences instance

  @override
  void initState() {
    super.initState();
    _initSharedPreferences(); // Initialize SharedPreferences and load reminders
  }

  // Initialize SharedPreferences and load reminders
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadReminders();
  }

  // Load reminders from SharedPreferences
  void _loadReminders() {
    final String? remindersJson = _prefs.getString('reminders'); // Use a different key
    if (remindersJson != null) {
      final List<dynamic> decodedList = json.decode(remindersJson);
      setState(() {
        _reminders.clear(); // Clear existing list before loading
        _reminders.addAll(decodedList.map((json) => Reminder.fromJson(json as Map<String, dynamic>)));
      });
    }
  }

  // Save reminders to SharedPreferences
  Future<void> _saveReminders() async {
    // Convert the list of Reminder objects to a list of JSON maps
    final List<Map<String, dynamic>> remindersMapList = _reminders.map((reminder) => reminder.toJson()).toList();
    // Encode the list of JSON maps to a single JSON string
    final String remindersJson = json.encode(remindersMapList);
    await _prefs.setString('reminders', remindersJson); // Save with the new key
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to add a new reminder to the list
  void _addReminder() { // Renamed from _addContact
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Only add if both title and description are not empty
    if (title.isNotEmpty && description.isNotEmpty) {
      setState(() {
        _reminders.add(Reminder(title, description)); // Add to _reminders
      });
      _saveReminders(); // Save reminders after adding
      // Clear the text fields after adding the reminder
      _titleController.clear();
      _descriptionController.clear();
    } else {
      // Show a message if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Title and Description.')),
      );
    }
  }

  // Function to show a confirmation dialog before deleting a reminder
  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Confirmation"),
          content: const Text("Are you sure you want to delete this Note?", style: TextStyle(color: Colors.black),),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            // Delete button
            TextButton(
              onPressed: () {
                setState(() {
                  _reminders.removeAt(index); // Remove the reminder from the list
                });
                _saveReminders(); // Save reminders after deleting
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder deleted.')),
                );
              },
              child: const Text("Delete"),
              style: TextButton.styleFrom(foregroundColor: Colors.red), // Style the delete button
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Text field for Title input
            TextField(
              controller: _titleController, // Changed to _titleController
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10), // Spacing
            // Text field for Description input
            TextField(
              controller: _descriptionController, // Changed to _descriptionController
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: null, // Allows for multiline input
              keyboardType: TextInputType.multiline, // Sets keyboard type for multiline
            ),
            const SizedBox(height: 10), // Spacing
            // Button to add a new reminder
            SizedBox(
              width: double.infinity, // Make button take full width
              child: ElevatedButton(
                onPressed: _addReminder, // Changed to _addReminder
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0), // Add vertical padding
                ),
                child: const Text(
                  "Add",
                  style: TextStyle(color: Colors.white, fontSize: 16.0), // Style text
                ),
              ),
            ),
            const SizedBox(height: 20), // Spacing before the list
            // Display message if no reminders are added
            if (_reminders.isEmpty) // Check _reminders list
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "No reminder added yet. Add a new reminder above!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            // Expanded widget to ensure ListView takes available space
            Expanded(
              child: ListView.builder(
                itemCount: _reminders.length, // Use _reminders.length
                itemBuilder: (context, index) {
                  final reminder = _reminders[index]; // Use reminder object
                  return GestureDetector(
                    onTap: () {
                      // Show delete confirmation dialog when a card is tapped
                      _showDeleteConfirmationDialog(index);
                    },
                    child: Card(
                      //elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.brown),
                        title: Text(
                          reminder.title, // Use reminder.title
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(reminder.description), // Use reminder.description
                        trailing: IconButton(
                          icon: const Icon(Icons.save_alt, color: Colors.blue), // Changed icon to info
                          onPressed: () {
                            // You can implement viewing full details here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Saved ${reminder.title}')),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}