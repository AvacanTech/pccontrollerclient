import 'dart:io';
import 'package:process_run/shell.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

void main() async {
  // Obtain the first IPv4 address
  String ipAddress = await getFirstIPv4Address();

  // Set up WebSocket handler
  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) async {
      try {
        String response = await executeCommand(message);
        webSocket.sink.add(response);
      } catch (e) {
        webSocket.sink.add('Error: $e');
      }
    });
  });

  // Start the server
  shelf_io.serve(handler, ipAddress, 4040).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}

// Function to get the first IPv4 address
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

// Function to execute a shell command and return its output
Future<String> executeCommand(String command) async {
  var shell = Shell();
  List<ProcessResult> result = await shell.run(command);
  return result.map((r) => r.outText.trim()).join('\n');
}
