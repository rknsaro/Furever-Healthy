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

  List<String> _suggestedQuestions = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onSuggestedQuestionTapped(String question) {
    _messageController.text = question;
    _suggestedQuestions = [];
    _sendMessage();
  }

  void _sendMessage() async {
    setState(() {
      _suggestedQuestions = [];
    });

    String userMessage = _messageController.text.trim();
    String userDisplayMessage = userMessage;
    String aiPromptMessage;

    const String systemContext =
        "You are a veterinary assistant specializing in cat and dog health. You can answer questions about: symptoms, health issues, treatments, medications, care instructions, veterinary advice, behavioral health concerns, when to see a vet, follow-up questions about previous advice, and any clarifications related to cats and dogs. ONLY if the user asks about completely unrelated topics (like recipes, weather, other animals, general knowledge, non-pet topics, etc.), politely respond: 'I appreciate your question, but I'm specifically designed to assist with symptoms and health concerns related to cats and dogs. You are welcome to ask me about any health issues your pets may be experiencing, and I'll be happy to help!' Use a friendly but professional tone.";

    const String responseFormatInstruction =
        "For health-related questions about cats and dogs, respond professionally in a multi-paragraph format. Use the following structure: 1) A compassionate introductory paragraph. 2) A section detailing possible causes, using bullet points. 3) A section with a clear recommendation (e.g., 'Seek Veterinary Attention Immediately' or 'Monitor Closely'). 4) A bulleted list of immediate, at-home actions. Format all headings and key actions using standard Markdown bolding (e.g., **Key Term:**).";

    if (userMessage.isEmpty && _selectedSymptoms.isNotEmpty) {
      final symptomList = _selectedSymptoms.join(", ");
      userDisplayMessage =
          'My pet is experiencing the following symptoms: $symptomList.';
      aiPromptMessage =
          '$systemContext\n\n$userDisplayMessage\n\n$responseFormatInstruction';
    } else if (userMessage.isNotEmpty) {
      aiPromptMessage =
          '$systemContext\n\n$userMessage\n\n$responseFormatInstruction';
    } else {
      return;
    }

    setState(() {
      _chatMessages.add({'sender': 'user', 'message': userDisplayMessage});
      _messageController.clear();
      _selectedSymptoms.clear();
      _isLoading = true;
    });

    final aiReply = await GeminiService.getAIResponse(aiPromptMessage);

    setState(() {
      _chatMessages.add({'sender': 'bot', 'message': aiReply});
      _isLoading = false;
    });

    // Generate follow-up questions based on the symptoms/health advice
    final followUpPrompt =
        "Based on this veterinary advice about cat/dog health: \"$aiReply\", generate exactly 4 short, relevant follow-up questions that a pet owner might ask. These should be practical questions about symptoms, care, or next steps. Output them as a simple numbered list (1., 2., 3., 4.) with no extra text or formatting.";
    final suggestedQuestionsResponse = await GeminiService.getAIResponse(
      followUpPrompt,
    );

    final questions = suggestedQuestionsResponse
        .split('\n')
        .where(
          (line) =>
              line.isNotEmpty && (line.contains('.') || line.contains('-')),
        )
        .map(
          (line) => line.replaceAll(RegExp(r'^\s*[\d\.\-\*]+\s*'), '').trim(),
        )
        .where((line) => line.isNotEmpty)
        .take(4)
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

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () => _onSuggestedQuestionTapped(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6F994A), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Color(0xFF6F994A),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
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
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF6F994A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Symptom Check',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: true,
              itemCount:
                  _chatMessages.length +
                  (_isLoading ? 1 : 0) +
                  1 +
                  (_suggestedQuestions.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // Calculate actual index from bottom
                int actualIndex = index;

                // Loading indicator at the top (index 0 in reverse)
                if (_isLoading && actualIndex == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Adjust index if loading
                if (_isLoading) actualIndex--;

                // Follow-up questions (shown right after the last bot message)
                if (_suggestedQuestions.isNotEmpty && actualIndex == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      children: _suggestedQuestions
                          .map((q) => _buildSuggestionChip(q))
                          .toList(),
                    ),
                  );
                }

                // Adjust index if suggestions shown
                if (_suggestedQuestions.isNotEmpty) actualIndex--;

                // Chat messages
                if (actualIndex < _chatMessages.length) {
                  final msg = _chatMessages.reversed.toList()[actualIndex];
                  final isUser = msg['sender'] == 'user';
                  final messageText = msg['message']!;
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
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
                                p: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                listBullet: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                    ),
                  );
                }

                // Initial card at the bottom
                actualIndex -= _chatMessages.length;
                if (actualIndex == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Center(
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
                              'Hi! What\'s concerning you about your pet today?',
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
                                _buildSymptomChip(
                                  'Diarrhea',
                                  _selectedSymptoms.contains('Diarrhea'),
                                ),
                                _buildSymptomChip(
                                  'Not eating',
                                  _selectedSymptoms.contains('Not eating'),
                                ),
                                _buildSymptomChip(
                                  'Vomiting',
                                  _selectedSymptoms.contains('Vomiting'),
                                ),
                                _buildSymptomChip(
                                  'Coughing',
                                  _selectedSymptoms.contains('Coughing'),
                                ),
                                _buildSymptomChip(
                                  'Excessive Scratching',
                                  _selectedSymptoms.contains(
                                    'Excessive Scratching',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.add, color: Color(0xFF6F994A), size: 30),
                  //   onPressed: () {
                  //     print('Add button tapped!');
                  //   },
                  // ),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        ),
        backgroundColor: isSelected
            ? const Color(0xFF6F994A)
            : const Color(0xFFD6DDF0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
