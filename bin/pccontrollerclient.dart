import 'dart:io';

import 'package:process_run/shell.dart';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';


void main(List<String> arguments) async {
  // Obtain IP Address and store in variable
  String ipAddress = '';
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type.name == 'IPv4') {
        ipAddress = addr.address;
      }
    }
  }

  // Set behavior performed upon reciept of a socket message
  var handler = webSocketHandler((webSocket) async {
    webSocket.stream.listen((message) async {
      webSocket.sink.add("echo $message");
      var shell = Shell();
      
      print(message.toString());
      List<ProcessResult> result = await shell.run('''
        $message
      ''');

      for (ProcessResult element in result) {
        print(element.outText);
      }

    });
  });

  print('Enter server IP Address: ');
  String? name = stdin.readLineSync();



  if (isValidIpAddress(ipAddress)) {
    final WebSocket socket = await WebSocket.connect(ipAddress);
    String hostName = Platform.localHostname;
    socket.add('Serving $hostName at ${name!}');
  } 


  shelf_io.serve(handler, ipAddress, 4040).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });

}



bool isValidIpAddress(String ipa) {
  final RegExp ipRegExp = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');

  if (!ipRegExp.hasMatch(ipa)) {
    return false; // Doesn't match the basic format of "X.X.X.X"
  }

  final parts = ipa.split('.');
  if (parts.length != 4) {
    return false; // IP address should have exactly 4 parts
  }

  for (var part in parts) {
    final int value = int.tryParse(part)!;
    if (value < 0 || value > 255) {
      return false; // Each part should be a number between 0 and 255
    }
  }

  return true;
}
