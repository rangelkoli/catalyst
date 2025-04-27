import 'package:flutter/material.dart';
import 'services/gemini_service.dart';

class GeminiDemoScreen extends StatefulWidget {
  const GeminiDemoScreen({super.key});

  @override
  State<GeminiDemoScreen> createState() => _GeminiDemoScreenState();
}

class _GeminiDemoScreenState extends State<GeminiDemoScreen> {
  final _controller = TextEditingController();
  String? _response;
  bool _loading = false;

  // TODO: Replace with your actual Gemini API key
  final gemini = GeminiService('YOUR_GEMINI_API_KEY');

  Future<void> _sendPrompt() async {
    setState(() {
      _loading = true;
      _response = null;
    });
    final result = await gemini.generateText(_controller.text);
    setState(() {
      _response = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter your prompt',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _sendPrompt,
              child:
                  _loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Ask Gemini'),
            ),
            const SizedBox(height: 24),
            if (_response != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_response!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
