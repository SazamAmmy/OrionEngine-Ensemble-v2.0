import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SurveyPage extends StatefulWidget {
  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  Map<String, String> answers = {}; // Stores user responses
  bool isLoading = false;

  // List of Questions
  final List<Map<String, dynamic>> questions = [
    {
      "id": "sustainability_level",
      "question": "How sustainable do you consider yourself?",
      "options": ["Very Sustainable", "Somewhat Sustainable", "Not Sustainable", "I don't know"]
    },
    {
      "id": "eco_choices",
      "question": "How often do you make eco-friendly choices?",
      "options": ["Always", "Often", "Rarely", "Never"]
    },
    {
      "id": "biggest_challenge",
      "question": "What is your biggest challenge in living sustainably?",
      "options": ["Lack of knowledge", "Sustainable products are expensive", "No time", "I don't think it's important"]
    },
    {
      "id": "purchase_preference",
      "question": "How important is sustainability when shopping?",
      "options": ["Very important", "Somewhat important", "Not important"]
    },
    {
      "id": "waste_reduction",
      "question": "How often do you try to reduce waste?",
      "options": ["Always", "Often", "Rarely", "Never"]
    },
    {
      "id": "energy_saving",
      "question": "Do you try to reduce your energy & water consumption?",
      "options": ["Yes", "Sometimes", "No"]
    },
    {
      "id": "wants_tips",
      "question": "Would you like to receive sustainability tips & challenges?",
      "options": ["Yes", "Maybe", "No"]
    },
  ];

  // Calculate Progress Percentage (Answered Questions / Total Questions)
  double get progress => answers.length / questions.length;

  // Submit Survey Data to Backend
  Future<void> _submitSurvey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token'); // Retrieve authentication token

    if (answers.length != questions.length) {
      _showMessage("Please answer all questions", true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/user/profile/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token' // Include the retrieved token
        },
        body: jsonEncode(answers), // Include the survey answers
      );

      if (response.statusCode == 200) {
        await prefs.setBool('survey_completed', true); // Mark survey as completed
        _showMessage("Survey submitted successfully!", false);
        Navigator.of(context).pushReplacementNamed('/main'); // Navigate to Home
      } else {
        final responseData = jsonDecode(response.body);
        _showMessage("Submission failed: ${responseData['message'] ?? 'Unknown error'}", true);
      }
    } catch (e) {
      _showMessage("Error: $e", true);
    }

    setState(() {
      isLoading = false;
    });
  }

  // Display SnackBar Message
  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Discover Your Sustainable Impact"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    "Survey Progress: ${(progress * 100).toInt()}%",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progress, // Dynamic Progress
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Survey Questions
            Expanded(
              child: ListView(
                children: questions.map((q) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q["question"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ...q["options"].map<Widget>((option) {
                        return RadioListTile(
                          title: Text(option),
                          value: option,
                          groupValue: answers[q["id"]],
                          onChanged: (value) {
                            setState(() {
                              answers[q["id"]] = value!; // Store user response
                            });
                          },
                        );
                      }).toList(),
                      SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: isLoading ? null : _submitSurvey,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
