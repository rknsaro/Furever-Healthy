import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'gemini_service.dart'; 

class SymptomCheckPage extends StatefulWidget {
  const SymptomCheckPage({super.key});

  @override
  State<SymptomCheckPage> createState() => _SymptomCheckPageState();
}

class _SymptomCheckPageState extends State<SymptomCheckPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _selectedSymptoms = [];
  final List<Map<String, String>> _chatMessages = []; 
  bool _isLoading = false;
  
  // NEW: State to hold suggested follow-up questions
  List<String> _suggestedQuestions = []; 

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Helper method to handle a tap on a suggested question chip
  void _onSuggestedQuestionTapped(String question) {
    _messageController.text = question;
    _suggestedQuestions = []; // Clear suggestions once one is tapped/used
    _sendMessage();
  }

  void _sendMessage() async {
    // Clear existing suggestions when a new message is sent
    setState(() {
      _suggestedQuestions = []; 
    });

    String userMessage = _messageController.text.trim();
    String userDisplayMessage = userMessage; 
    String aiPromptMessage; 
    
    // --- 1. Define the AI Formatting Template for the Main Response (NEW/UPDATED) ---
    const String responseFormatInstruction = 
      "Respond professionally in a multi-paragraph format. Use the following structure: 1) A compassionate introductory paragraph. 2) A section detailing possible causes, using bullet points. 3) A section with a clear recommendation (e.g., 'Seek Veterinary Attention Immediately' or 'Monitor Closely'). 4) A bulleted list of immediate, at-home actions. Format all headings and key actions using standard Markdown bolding (e.g., **Key Term:**).";


    // 2. Logic to handle symptom chips vs. free-text input
    if (userMessage.isEmpty && _selectedSymptoms.isNotEmpty) {
      // SCENARIO: User clicked symptom chips
      final symptomList = _selectedSymptoms.join(", ");
      userDisplayMessage = 'My pet is experiencing the following symptoms: $symptomList.';

      // The AI prompt includes the clean message PLUS the template instruction
      aiPromptMessage = '$userDisplayMessage $responseFormatInstruction';

    } else if (userMessage.isNotEmpty) {
      // SCENARIO: User typed a message
      aiPromptMessage = userMessage; 
      // If it's a follow-up, we don't need to repeat the format instruction, 
      // but we could prepend it to ensure continuity if needed. 
      // For simplicity, we keep it as just the typed message for now.
    } else {
      return;
    }

    // 3. Add the clean message to the chat for display
    setState(() {
      _chatMessages.add({'sender': 'user', 'message': userDisplayMessage});
      _messageController.clear();
      _selectedSymptoms.clear();
      _isLoading = true;
    });

    // 4. Send the full prompt (aiPromptMessage) to the Gemini service for the MAIN RESPONSE
    final aiReply = await GeminiService.getAIResponse(aiPromptMessage);

    setState(() {
      _chatMessages.add({'sender': 'bot', 'message': aiReply});
      _isLoading = false;
    });
    
    // --- 5. New: Send a follow-up request to get suggested questions ---
    final followUpPrompt = "Based on this advice: \"$aiReply\", generate 4 short, single-line follow-up questions for the user. Output them as a numbered list only, with no other text.";
    
    // NOTE: This assumes GeminiService.getAIResponse can handle this. 
    // You may need a specialized service method if your API wrapper limits total tokens.
    final suggestedQuestionsResponse = await GeminiService.getAIResponse(followUpPrompt);
    
    // Simple parsing to extract questions (assuming they come back as a numbered list)
    final questions = suggestedQuestionsResponse
        .split('\n')
        .where((line) => line.isNotEmpty && (line.contains('.') || line.contains('-'))) // Basic filter for list items
        .map((line) => line.replaceAll(RegExp(r'^\s*[\d\.\-\*]+\s*'), '').trim()) // Remove numbering/bullets
        .take(4) // Take only the first 4
        .toList();

    setState(() {
      _suggestedQuestions = questions;
    });
  }

  void _onSymptomChipTapped(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }
  
  // NEW: Widget for the suggested question chips
  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () => _onSuggestedQuestionTapped(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6F994A), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF6F994A)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0D6),
      appBar: AppBar(
        // ... (AppBar code remains the same) ...
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF6F994A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/furever2.png',
              height: 40,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {
              print('Notification icon tapped on Symptom Check page!');
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              reverse: true, 
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ..._chatMessages.reversed.map((msg) {
                  final isUser = msg['sender'] == 'user';
                  final messageText = msg['message']!;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFFC5E7A6) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: isUser
                          ? Text(
                              messageText,
                              style: const TextStyle(fontSize: 16),
                            )
                          : MarkdownBody(
                              data: messageText,
                              shrinkWrap: true,
                              selectable: false,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 16, color: Colors.black87),
                                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                listBullet: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                    ),
                  );
                }),
                
                const SizedBox(height: 20),
                
                // NEW: Suggested Questions Display
                if (_suggestedQuestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      children: _suggestedQuestions
                          .map((q) => _buildSuggestionChip(q))
                          .toList(),
                    ),
                  ),

                // Original welcome card
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hi! What\'s concerning you today?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Select a symptom below or describe in your own words:',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildSymptomChip('Diarrhea', _selectedSymptoms.contains('Diarrhea')),
                            _buildSymptomChip('Not eating', _selectedSymptoms.contains('Not eating')),
                            _buildSymptomChip('Vomiting', _selectedSymptoms.contains('Vomiting')),
                            _buildSymptomChip('Coughing', _selectedSymptoms.contains('Coughing')),
                            _buildSymptomChip('Excessive Scratching', _selectedSymptoms.contains('Excessive Scratching')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF6F994A), size: 30),
                    onPressed: () {
                      print('Add button tapped!');
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Describe your pet\'s symptoms',
                        fillColor: const Color(0xFFE8F0D6),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6F994A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onSymptomChipTapped(label),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isSelected ? const Color(0xFF6F994A) : const Color(0xFFD6DDF0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
    );
  }
}