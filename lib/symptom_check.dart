import 'package:flutter/material.dart';
import 'gemini_service.dart'; // Ensure this file matches the updated GeminiService

class SymptomCheckPage extends StatefulWidget {
  const SymptomCheckPage({super.key});

  @override
  State<SymptomCheckPage> createState() => _SymptomCheckPageState();
}

class _SymptomCheckPageState extends State<SymptomCheckPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _selectedSymptoms = [];
  final List<Map<String, String>> _chatMessages = []; // Stores messages with sender info
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    String userMessage = _messageController.text.trim();

    if (userMessage.isEmpty && _selectedSymptoms.isNotEmpty) {
      userMessage = 'My pet is experiencing the following symptoms: ${_selectedSymptoms.join(", ")}.';
    }

    if (userMessage.isEmpty) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'message': userMessage});
      _messageController.clear();
      _selectedSymptoms.clear();
      _isLoading = true;
    });

    final aiReply = await GeminiService.getAIResponse(userMessage);

    setState(() {
      _chatMessages.add({'sender': 'bot', 'message': aiReply});
      _isLoading = false;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              reverse: true, // Scroll to bottom on new message
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),
                  ..._chatMessages.map((msg) {
                    final isUser = msg['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFFC5E7A6) : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          msg['message']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
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
