import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

//import 'package:shared_preferences/shared_preferences.dart';



void main(List<String> arguments) async {

   for (var interface in await NetworkInterface.list()) {
      print('== Interface: ${interface.name} ==');
      for (var addr in interface.addresses) {
        print(
            '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
      }
    }


  var handler = webSocketHandler((webSocket) async {

    webSocket.stream.listen((message) async {


      webSocket.sink.add("echo $message");
       var shell = Shell();


      await shell.run('''
        $message
      ''');
      print(message.toString());

    });
  });

  shelf_io.serve(handler, '192.168.12.170', 4040).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });

}