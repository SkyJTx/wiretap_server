import 'dart:async';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:wiretap_server/dotenv.dart';

class MailRepo {
  final inputController = StreamController<Message>();
  late final StreamSubscription<Message> inputSubscription;
  late final SmtpServer _smtpServer;
  late final PersistentConnection smtpServer;

  MailRepo.createInstance() {
    _smtpServer = gmail(env['EMAIL']!, env['EMAIL_PASSWORD']!);
    smtpServer = PersistentConnection(_smtpServer);
    inputSubscription = inputController.stream.listen((message) async {
      try {
        await smtpServer.send(message);
      } catch (e) {
        print('Error sending email: $e');
      }
    });
  }

  static MailRepo? _instance;

  factory MailRepo() {
    _instance ??= MailRepo.createInstance();
    return _instance!;
  }

  void dispose() {
    inputSubscription.cancel();
    smtpServer.close();
  }

  Message createMessage(String subject, String body) {
    final message = Message()
      ..from = Address(env['EMAIL']!, 'Wiretap Server')
      ..recipients.add(env['EMAIL_SENDTO']!)
      ..subject = 'Wiretap Server Notification'
      ..text = body;
    return message;
  }

  void sendMail(Message msg) {
    inputController.add(msg);
  }
}
