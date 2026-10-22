import 'package:flutter/material.dart';
import 'package:waayzy_native_bridge/waayzy_native_bridge.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: PhoneHintPage());
}

/// On-device test bed: needs an Android phone with a SIM and Play services.
class PhoneHintPage extends StatefulWidget {
  const PhoneHintPage({super.key});

  @override
  State<PhoneHintPage> createState() => _PhoneHintPageState();
}

class _PhoneHintPageState extends State<PhoneHintPage> {
  final _log = <String>[];
  late final PhoneHint _hint = PhoneHint(
    onLog: (level, message, _) =>
        setState(() => _log.add("${level.name}: $message")),
  );
  String _result = 'Nothing requested yet';

  Future<void> _request() async {
    final number = await _hint.requestPhoneNumber();
    setState(() => _result = number ?? 'No number (dismissed or unavailable)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('waayzy_native_bridge')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton(
              onPressed: _request,
              child: const Text('Request phone number'),
            ),
            const SizedBox(height: 16),
            Text('Result: $_result'),
            const SizedBox(height: 16),
            for (final line in _log) Text(line),
          ],
        ),
      ),
    );
  }
}
