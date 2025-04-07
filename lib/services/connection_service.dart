import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  Socket? _socket;
  bool _isConnected = false;
  final _connectionController = StreamController<bool>.broadcast();
  String? currentIp;
  int? currentPort;
  bool _isConnecting = false;
  StreamSubscription<Uint8List>? _socketSubscription;
  bool _isDisposed = false;

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
 
  Future<void> connect(String ip, int port) async {
    if (_isDisposed) {
      throw Exception('ConnectionService has been disposed');
    }

    // If already connected to the same server, don't reconnect
    if (_isConnected && currentIp == ip && currentPort == port) {
      return;
    }

    // If already trying to connect, don't start another connection attempt
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      // Only disconnect if we're connecting to a different server
      if (currentIp != ip || currentPort != port) {
        await _disconnect();
      }

      currentIp = ip;
      currentPort = port;

      _socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );

      // Send ObjectOutputStream header
      final header =
          ByteData(4)
            ..setUint8(0, 0xac) // STREAM_MAGIC
            ..setUint8(1, 0xed) // STREAM_MAGIC
            ..setUint8(2, 0x00) // STREAM_VERSION
            ..setUint8(3, 0x05); // STREAM_VERSION

      _socket!.add(header.buffer.asUint8List());
      await _socket!.flush();

      // Cancel any existing subscription
      await _socketSubscription?.cancel();

      // Set up new subscription
      _socketSubscription = _socket!.listen(
        (Uint8List data) {
          _handleConnectionSuccess();
        },
        onError: (error) {
          _handleConnectionError(error.toString());
        },
        onDone: () {
          _handleDisconnection();
        },
      );
    } catch (e) {
      _handleConnectionError(e.toString());
    } finally {
      _isConnecting = false;
    }
  }

  void _handleConnectionSuccess() {
    if (!_isConnected) {
      _isConnected = true;
      _connectionController.add(true);
    }
  }

  void _handleConnectionError(String error) {
    if (_isConnected) {
      _isConnected = false;
      _connectionController.add(false);
      _disconnect();
    }
  }

  void _handleDisconnection() {
    if (_isConnected) {
      _isConnected = false;
      _connectionController.add(false);
      _disconnect();
    }
  }

  Future<void> _disconnect() async {
    await _socketSubscription?.cancel();
    try {
      if (_socket != null) {
        await _socket!.flush();
        await _socket!.close();
      }
    } catch (e) {
      // Ignore errors during disconnect
    } finally {
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      _socketSubscription = null;
    }
  }

  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _disconnect();
      _connectionController.close();
    }
  }
}
