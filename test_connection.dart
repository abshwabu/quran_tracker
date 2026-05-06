import 'dart:io';

void main() async {
  final host = '109.199.121.222';
  final port = 8001;
  
  print('Testing connection to $host:$port...');
  
  try {
    final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
    print('SUCCESS: Connected to $host:$port');
    socket.destroy();
  } catch (e) {
    print('FAILURE: Could not connect to $host:$port');
    print('Error: $e');
  }
}
