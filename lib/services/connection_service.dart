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
      // Connect to the server with a longer timeout
      _socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      _connectionAttempts = 0; // Reset attempts on successful connection
      _connectionController.add(true);

      // Set up socket listeners for BytesWiz POS
      _socket!.listen(
        (data) {
          debugPrint(
              'Received data from BytesWiz POS: ${String.fromCharCodes(data)}');
          // Handle specific BytesWiz POS responses
          _handleBytesWizResponse(data);
        },
        onError: (error) {
          debugPrint('BytesWiz POS socket error: $error');
          _handleDisconnection('Socket error: $error');
        },
        onDone: () {
          debugPrint('BytesWiz POS connection closed');
          _handleDisconnection('Socket connection closed');
        },
      );

      // Send initial handshake for BytesWiz POS
      _sendBytesWizHandshake();

      debugPrint('Connected to BytesWiz POS at $ip:$port');
    } catch (e) {
      debugPrint('Connection error to BytesWiz POS: $e');
      _handleDisconnection('Connection error: $e');
    } finally {
      _isConnecting = false;
    }
  }

  void _sendBytesWizHandshake() {
    if (_socket == null) return;

    try {
      // Send BytesWiz POS specific handshake
      final handshake = [
        0xac, 0xed, // STREAM_MAGIC
        0x00, 0x05, // STREAM_VERSION
        0x77, // TC_BLOCKDATA
        0x00, 0x0A, // Length of handshake data
        0x42, 0x79, 0x74, 0x65, 0x73, 0x57, 0x69, 0x7A, // "BytesWiz"
        0x50, 0x4F, 0x53, // "POS"
      ];

      _socket!.add(Uint8List.fromList(handshake));
      debugPrint('Sent BytesWiz POS handshake');
    } catch (e) {
      debugPrint('Error sending BytesWiz POS handshake: $e');
    }
  }

  void _handleBytesWizResponse(List<int> data) {
    // Handle specific BytesWiz POS responses
    if (data.length >= 2 && data[0] == 0xac && data[1] == 0xed) {
      debugPrint('Received valid BytesWiz POS response');
      // Process the response based on BytesWiz POS protocol
    }
  }

  void _handleDisconnection(String reason) {
    debugPrint('Handling BytesWiz POS disconnection: $reason');
    _socket?.close();
    _socket = null;
    _connectionController.add(false);

    // Attempt to reconnect if we haven't exceeded max attempts
    if (_connectionAttempts < _maxConnectionAttempts &&
        _currentIp != null &&
        _currentPort != null) {
      _connectionAttempts++;
      debugPrint(
          'Attempting to reconnect to BytesWiz POS (attempt $_connectionAttempts of $_maxConnectionAttempts)');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        if (_currentIp != null && _currentPort != null) {
          connect(_currentIp!, _currentPort!);
        }
      });
    } else if (_connectionAttempts >= _maxConnectionAttempts) {
      debugPrint('Max reconnection attempts to BytesWiz POS reached');
      _connectionAttempts = 0; // Reset for future connection attempts
    }
  }

  Future<void> disconnect() async {
    debugPrint('Disconnecting from BytesWiz POS...');
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
