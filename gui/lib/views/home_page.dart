import 'package:flutter/material.dart';
import '../controllers/main_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MainController _controller = MainController();

  @override
  void initState() {
    super.initSate();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Lab - Flutter Control Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        girdDelegate: null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text('Status: ${_controller.currentData?.status ?? "N/A"}'),
              Text('Estimate: ${_controller.currentData?.estimate ?? 0.0}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _controller.fetchData(),
                child: const Text('Refresh Data'),
              ),
            ],
            if (_controller.errorMessage.isNotEmpty)
              Text(
                'Error: ${_controller.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}