// Fully updated: polished quiz-style UI with accurate animated progress bar
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sustainableapp/services/api_service.dart';
import 'dart:convert';
import 'survey_success_page.dart';
import 'package:sustainableapp/auth_service.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});
  @override
  SurveyPageState createState() => SurveyPageState();
}

class SurveyPageState extends State<SurveyPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
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

  Future<void> _submitSurvey() async {

    if (answers.length != questions.length) {
      _showMessage("Please answer all questions before submitting.", true);
      return;
    }

    if (mounted) setState(() => isLoading = true);

    const url = 'https://direct-frog-amused.ngrok-free.app/api/user/profile/';

    try {
      final response = await ApiService.post(url, body: answers);
      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('survey_completed', true);
        _showMessage("Survey submitted successfully!", false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SurveySuccessPage()),
        );
      } else {
        _showMessage(
            "Submission failed: ${responseData['message'] ?? 'Unknown error'}",
            true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage("Error submitting survey: $e", true);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Widget _buildQuestionPage(int index) {
    final q = questions[index];
    final questionId = q["id"] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Text(
            "Select an answer",
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q["question"],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: (q["options"] as List<String>).map((option) {
                  final isSelected = answers[questionId] == option;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => answers[questionId] = option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber.shade700 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.amber : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == questions.length - 1;
    final isAnswered = answers.containsKey(questions[_currentPage]['id']);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: _currentPage > 0
                          ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                          : null,
                    ),
                    Text(
                      "${_currentPage + 1}/${questions.length}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.more_vert, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / questions.length,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: questions.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildQuestionPage(index),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: isLast
                      ? (answers.length == questions.length && !isLoading ? _submitSurvey : null)
                      : (isAnswered
                      ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease)
                      : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isLast
                        ? (answers.length == questions.length)
                        : isAnswered)
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    foregroundColor: Colors.green.shade800,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                    isLast ? "Submit" : "Next",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}