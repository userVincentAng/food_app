import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  Socket? _socket;
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _socket != null;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;
  String? _currentIp;
  int? _currentPort;
  Timer? _reconnectTimer;
  int _connectionAttempts = 0;
  static const int _maxConnectionAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  bool _handshakeReceived = false;
  bool _connectionEstablished = false;
  bool _forceReconnect = false;

  String? get currentIp => _currentIp;
  int? get currentPort => _currentPort;
  Socket? get socket => _socket;

  Future<void> connect(String ip, int port) async {
    // If already connected to the same server and not forcing reconnect, do nothing
    if (isConnected &&
        _currentIp == ip &&
        _currentPort == port &&
        !_forceReconnect) {
      debugPrint('Already connected to $ip:$port');
      return;
    }

    // If already trying to connect, don't start another connection attempt
    if (_isConnecting) {
      debugPrint('Connection attempt already in progress');
      return;
    }

    _isConnecting = true;
    _handshakeReceived = false;
    _connectionEstablished = false;
    _forceReconnect = false;

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
      debugPrint(
          'Attempting to connect to $ip:$port (attempt ${_connectionAttempts + 1})');

      // Connect to the server with a longer timeout
      _socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 15))
              .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Connection timed out after 15 seconds');
      });

      _connectionAttempts = 0; // Reset attempts on successful connection

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
      await _sendBytesWizHandshake();

      // Wait for handshake response with timeout
      await _waitForHandshakeResponse();

      // Consider connection established even if we don't get a handshake response
      // Some POS systems might not respond to handshakes but still accept data
      _connectionEstablished = true;
      _connectionController.add(true);
      debugPrint('Connected to BytesWiz POS at $ip:$port');
    } catch (e) {
      debugPrint('Connection error: $e');
      _handleConnectionError(e);
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _waitForHandshakeResponse() async {
    if (_handshakeReceived) return;

    try {
      // Wait for handshake response with a reasonable timeout
      await Future.delayed(const Duration(seconds: 5));

      // If we still haven't received a handshake response, log it but continue
      if (!_handshakeReceived) {
        debugPrint(
            'No handshake response received after 5 seconds, continuing anyway');
      }
    } catch (e) {
      debugPrint('Error waiting for handshake: $e');
      // Continue anyway, as some POS systems might not respond to handshakes
    }
  }

  Future<void> _sendBytesWizHandshake() async {
    if (_socket == null) return;

    try {
      // Simplified handshake - just send the magic bytes
      final handshake = [0xac, 0xed];

      _socket!.add(Uint8List.fromList(handshake));
      await _socket!.flush();
      debugPrint('Sent BytesWiz POS handshake');
    } catch (e) {
      debugPrint('Error sending BytesWiz POS handshake: $e');
      // Don't throw an exception here, just log the error
      // Some POS systems might not respond to handshakes
    }
  }

  void _handleBytesWizResponse(List<int> data) {
    // Handle specific BytesWiz POS responses
    // The POS system seems to respond with just the magic bytes (0xAC 0xED)
    if (data.length >= 2 && data[0] == 0xac && data[1] == 0xed) {
      debugPrint('Received valid BytesWiz POS response');
      _handshakeReceived = true;

      // If we haven't established the connection yet, do it now
      if (!_connectionEstablished) {
        _connectionEstablished = true;
        _connectionController.add(true);
      }
    }
  }

  void _handleDisconnection(String reason) {
    debugPrint('Handling BytesWiz POS disconnection: $reason');

    // Only close the socket if we're not in a reconnection attempt
    if (_connectionAttempts >= _maxConnectionAttempts) {
      _socket?.close();
      _socket = null;
      _connectionController.add(false);
      _handshakeReceived = false;
      _connectionEstablished = false;
    }

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
          // Force reconnect on next attempt
          _forceReconnect = true;
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
    _handshakeReceived = false;
    _connectionEstablished = false;
    _forceReconnect = false;
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

  /// Sends data to the POS system in a format it can understand
  /// Returns true if the data was sent successfully
  Future<bool> sendDataToPOS(Map<String, dynamic> data) async {
    if (_socket == null) {
      debugPrint('Cannot send data: Socket is null');
      return false;
    }

    try {
      // Convert data to JSON
      final jsonString = jsonEncode(data);
      debugPrint('Sending data to POS: $jsonString');

      // Create a UTF-8 encoded byte array of the JSON string
      final jsonBytes = utf8.encode(jsonString);

      // Create a buffer for the entire message
      final buffer = BytesBuilder();

      // Add BytesWiz POS protocol header - simplified to match what the POS expects
      buffer.add([0xac, 0xed]);

      // Add length of data (2 bytes, big-endian)
      final dataLength = jsonBytes.length;
      buffer.add([
        (dataLength >> 8) & 0xFF, // High byte
        dataLength & 0xFF, // Low byte
      ]);

      // Add the JSON data
      buffer.add(jsonBytes);

      // Get the complete message
      final completeMessage = buffer.toBytes();

      // Send the complete message in a single write operation
      _socket!.add(completeMessage);
      await _socket!.flush();

      debugPrint('Data sent to POS successfully');
      return true;
    } catch (e) {
      debugPrint('Error sending data to POS: $e');
      return false;
    }
  }

  void _handleConnectionError(Object e) {
    // Implement the logic to handle the connection error
    // This is a placeholder and should be replaced with the actual implementation
    debugPrint('Handling connection error: $e');
  }
}
