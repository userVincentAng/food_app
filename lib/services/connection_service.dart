import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  Socket? _socket;
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _socket != null && _socket!.done == false;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;
  String? _currentIp;
  int? _currentPort;
  Timer? _reconnectTimer;
  int _connectionAttempts = 0;
  static const int _maxConnectionAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  String? get currentIp => _currentIp;
  int? get currentPort => _currentPort;
  Socket? get socket => _socket;

  Future<void> connect(String ip, int port) async {
    // If already connected to the same server, do nothing
    if (isConnected && _currentIp == ip && _currentPort == port) {
      debugPrint('Already connected to $ip:$port');
      return;
    }

    // If already trying to connect, don't start another connection attempt
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;

    // If connected to a different server, disconnect first
    if (isConnected) {
      await disconnect();
    }

    // Reset connection attempts if connecting to a different server
    if (_currentIp != ip || _currentPort != port) {
      _connectionAttempts = 0;
    }

    _currentIp = ip;
    _currentPort = port;

    try {
      _socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      _connectionAttempts = 0; // Reset attempts on successful connection
      _connectionController.add(true);

      // Set up socket listeners
      _socket!.listen(
        (data) {
          debugPrint('Received data: ${String.fromCharCodes(data)}');
        },
        onError: (error) {
          debugPrint('Socket error: $error');
          _handleDisconnection('Socket error: $error');
        },
        onDone: () {
          debugPrint('Socket connection closed');
          _handleDisconnection('Socket connection closed');
        },
      );

      debugPrint('Connected to $ip:$port');
    } catch (e) {
      debugPrint('Connection error: $e');
      _handleDisconnection('Connection error: $e');
    } finally {
      _isConnecting = false;
    }
  }

  void _handleDisconnection(String reason) {
    debugPrint('Handling disconnection: $reason');
    _socket?.close();
    _socket = null;
    _connectionController.add(false);

    // Attempt to reconnect if we haven't exceeded max attempts
    if (_connectionAttempts < _maxConnectionAttempts &&
        _currentIp != null &&
        _currentPort != null) {
      _connectionAttempts++;
      debugPrint(
          'Attempting to reconnect (attempt $_connectionAttempts of $_maxConnectionAttempts)');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        if (_currentIp != null && _currentPort != null) {
          connect(_currentIp!, _currentPort!);
        }
      });
    } else if (_connectionAttempts >= _maxConnectionAttempts) {
      debugPrint('Max reconnection attempts reached');
      _connectionAttempts = 0; // Reset for future connection attempts
    }
  }

  Future<void> disconnect() async {
    debugPrint('Disconnecting...');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectionAttempts = 0;
    await _socket?.close();
    _socket = null;
    _currentIp = null;
    _currentPort = null;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _connectionController.close();
  }
}
