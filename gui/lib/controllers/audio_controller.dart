import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class AudioController extends ChangeNotifier {
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isStreaming = false;
  String _statusMessage = 'System Ready (/mnt/javid_data/opt)';
  
  WebSocketChannel? _channel;
  // กำหนด URL ของ WebSocket Backend ของเรา (ปรับเปลี่ยนพอร์ตหรือไอพีตามระบบจริงได้เลยครับ)
  final String _wsUrl = 'ws://127.0.0.1:8000/ws/audio';

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isStreaming => _isStreaming;
  String get statusMessage => _statusMessage;

  void toggleRecord() {
    _isRecording = !_isRecording;
    _statusMessage = _isRecording ? 'Recording Audio...' : 'Recording Stopped';
    
    // ส่งคำสั่งผ่าน WebSocket ไปยัง Backend ถ้าเชื่อมต่ออยู่
    _sendWsCommand(_isRecording ? 'START_RECORD' : 'STOP_RECORD');
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    _statusMessage = _isPlaying ? 'Playing Audio Stream...' : 'Playback Paused';
    
    _sendWsCommand(_isPlaying ? 'START_PLAY' : 'STOP_PLAY');
    notifyListeners();
  }

  void toggleStream() {
    if (_isStreaming) {
      _disconnectWebSocket();
    } else {
      _connectWebSocket();
    }
  }

  void _connectWebSocket() {
    try {
      _statusMessage = 'Connecting to WebSocket...';
      notifyListeners();

      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isStreaming = true;
      _statusMessage = 'WebSocket Streaming Active';

      // รับข้อมูลหรือสถานะกลับมาจาก Backend
      _channel!.stream.listen(
        (message) {
          debugPrint('Server msg: $message');
        },
        onError: (error) {
          _statusMessage = 'Stream Error: $error';
          _isStreaming = false;
          notifyListeners();
        },
        onDone: () {
          _statusMessage = 'Stream Disconnected';
          _isStreaming = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _statusMessage = 'Connection Failed: $e';
      _isStreaming = false;
    }
    notifyListeners();
  }

  void _disconnectWebSocket() {
    _channel?.sink.close(status.normalClosure);
    _channel = null;
    _isStreaming = false;
    _statusMessage = 'Stream Disconnected';
    notifyListeners();
  }

  void _sendWsCommand(String command) {
    if (_isStreaming && _channel != null) {
      _channel!.sink.add(command);
    }
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    super.dispose();
  }
}