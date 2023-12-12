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

  String kickBackMessage = '';
  // Set behavior performed upon reciept of a socket message
  var handler = webSocketHandler((webSocket) async {
    webSocket.stream.listen((message) async {
      
      var shell = Shell();
      
      print(message.toString());

      List<ProcessResult> result = await shell.run('''
        $message
      ''');
      kickBackMessage = message + ':\n';
      for (ProcessResult element in result) {
        print(element.outText);
        kickBackMessage += element.outText + '\n';
      }

      webSocket.sink.add(kickBackMessage);

    });
  });

  shelf_io.serve(handler, ipAddress, 4040).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });

}




