import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;

  io.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected == true;

  void connect({
    required String baseUrl,
    required String token,
    bool autoConnect = true,
  }) {
    if (_socket != null) {
      disconnect();
    }

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    if (autoConnect) {
      _socket!.connect();
    }
  }

  void start() {
    _socket?.connect();
  }

  void joinReport(String reportId) {
    _socket?.emit('join:report', reportId);
  }

  void leaveReport(String reportId) {
    _socket?.emit('leave:report', reportId);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
