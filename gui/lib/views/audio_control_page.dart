import 'package:flutter/material.dart';
import '../../controllers/audio_controller.dart';

class AudioControlPage extends StatefulWidget {
  const AudioControlPage({super.key});

  @override
  State<AudioControlPage> createState() => _AudioControlPageState();
}

class _AudioControlPageState extends State<AudioControlPage> {
  final AudioController _controller = AudioController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JAVID AUDIO CONTROL',
          style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _controller.statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildControlButton(
              label: _controller.isRecording ? 'STOP RECORDING' : 'START RECORDING',
              icon: Icons.mic,
              isActive: _controller.isRecording,
              activeColor: Colors.redAccent,
              onPressed: _controller.toggleRecord,
            ),
            const SizedBox(height: 16),
            _buildControlButton(
              label: _controller.isPlaying ? 'PAUSE PLAYBACK' : 'PLAY AUDIO',
              icon: Icons.play_arrow,
              isActive: _controller.isPlaying,
              activeColor: Colors.greenAccent,
              onPressed: _controller.togglePlay,
            ),
            const SizedBox(height: 16),
            _buildControlButton(
              label: _controller.isStreaming ? 'DISCONNECT STREAM' : 'START STREAM (WS)',
              icon: Icons.rss_feed,
              isActive: _controller.isStreaming,
              activeColor: Colors.blueAccent,
              onPressed: _controller.toggleStream,
            ),
            const Spacer(),
            const Text(
              'Agent Lab Co., Ltd. - JTDevelopTech',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? activeColor : const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}