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
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 2);
  static const Duration connectionTimeout = Duration(seconds: 10);

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
  Socket? get socket => _socket;
  bool get isConnecting => _isConnecting;

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
    _reconnectAttempts = 0;
    _cancelReconnectTimer();

    try {
      // Only disconnect if we're connecting to a different server
      if (currentIp != ip || currentPort != port) {
        await _disconnect();
      }

      currentIp = ip;
      currentPort = port;

      // Connect with timeout
      _socket = await Socket.connect(
        ip,
        port,
        timeout: connectionTimeout,
      ).timeout(
        connectionTimeout,
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      // Send ObjectOutputStream header
      final header = ByteData(4)
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

      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
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
      _cancelReconnectTimer();
    }
  }

  void _handleConnectionError(String error) {
    if (_isConnected) {
      _isConnected = false;
      _connectionController.add(false);
      _disconnect();
    } else if (_isConnecting) {
      _isConnecting = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  void _handleDisconnection() {
    if (_isConnected) {
      _isConnected = false;
      _connectionController.add(false);
      _disconnect();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < maxReconnectAttempts &&
        currentIp != null &&
        currentPort != null) {
      _reconnectAttempts++;
      _cancelReconnectTimer();
      _reconnectTimer = Timer(reconnectDelay, () {
        if (!_isConnected && !_isConnecting && !_isDisposed) {
          connect(currentIp!, currentPort!);
        }
      });
    }
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _disconnect() async {
    _cancelReconnectTimer();
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
      _cancelReconnectTimer();
      _disconnect();
      _connectionController.close();
    }
  }
}
