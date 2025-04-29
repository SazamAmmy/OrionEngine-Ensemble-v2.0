import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'survey_success_page.dart';
import 'package:sustainableapp/auth_service.dart';


class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});
  @override
  SurveyPageState createState() => SurveyPageState();
}

class SurveyPageState extends State<SurveyPage> {
  Map<String, String> answers = {};
  bool isLoading = false;

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
      "options": [
        "Lack of knowledge",
        "Sustainable products are expensive",
        "No time",
        "I don't think it's important"
      ]
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

  double get progress => answers.length / questions.length;

  Future<void> _submitSurvey() async {
    final token = await AuthService.getValidAccessToken();

    if (answers.length != questions.length) {
      _showMessage("Please answer all questions", true);
      return;
    }

    if (token == null) {
      _showMessage("⚠️ You must be logged in to submit the survey", true);
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('https://direct-frog-amused.ngrok-free.app/api/user/profile/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(answers),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('survey_completed', true);
        _showMessage("Survey submitted successfully!", false);

        // Navigate to success page
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SurveySuccessPage()),
        );
      }
      else if (response.statusCode == 429) {   // 🚀 Handle Rate Limit
        final errorMessage = responseData['error'] ?? "Rate limit exceeded. Please wait and try again.";
        _showMessage(errorMessage, true);
      }
      else {
        _showMessage("Submission failed: ${responseData['message'] ?? 'Unknown error'}", true);
      }
    } catch (e) {
      _showMessage("Error: $e", true);
    }

    setState(() => isLoading = false);
  }


  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Your Sustainable Impact"),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Answer a few quick questions to help us personalize your sustainability journey!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  Text(
                    "Progress: ${(progress * 100).toInt()}%",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: questions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    var q = questions[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q["question"],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: q["options"].map<Widget>((option) {
                                bool selected = answers[q["id"]] == option;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        answers.remove(q["id"]);
                                      } else {
                                        answers[q["id"]] = option;
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: selected ? Colors.green : Colors.white,
                                      border: Border.all(
                                        color: selected ? Colors.green : Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: selected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (answers.length == questions.length && !isLoading)
                    ? _submitSurvey
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: answers.length == questions.length
                      ? Colors.white
                      : Colors.grey.shade300,
                  foregroundColor: answers.length == questions.length
                      ? Colors.green
                      : Colors.grey.shade600,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: answers.length == questions.length
                        ? Colors.green
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
