import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

void main() async {
  runServer();
}

void runServer() {
  getFirstIPv4Address().then((ipAddress) {
    startWebSocketServer(ipAddress, 4040);
  }).catchError((e) {
    print('Error obtaining IP address: $e');
    // Consider retrying or exiting the application
  });
}

Future<void> startWebSocketServer(String ipAddress, int port) async {
  try {
    var handler = webSocketHandler((webSocket) {
      webSocket.stream.listen(
        (message) {
          executeCommand(message).then((response) {
            webSocket.sink.add(response);
          }).catchError((e) {
            print('Error executing command: $e');
            webSocket.sink.add('Error executing command');
          });
        },
        onDone: () => print('WebSocket disconnected.'),
        onError: (error) => print('WebSocket error: $error'),
      );
    });

    shelf_io.serve(handler, ipAddress, port).then((server) {
      print('Serving at ws://${server.address.host}:${server.port}');
    }).catchError((e) {
      print('Error starting server: $e');
      // Implement server restart or recovery logic
    });
  } catch (e) {
    print('Error setting up server: $e');
    // Consider retrying or exiting the application
  }
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
