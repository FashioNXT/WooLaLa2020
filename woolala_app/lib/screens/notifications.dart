import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:meta/meta.dart';
import 'package:woolala_app/screens/profile_screen.dart';
import 'package:woolala_app/screens/login_screen.dart';

class LocalNotificationWidget extends StatefulWidget {
  @override
  _LocalNotificationWidgetState createState() =>
      _LocalNotificationWidgetState();
}

class _LocalNotificationWidgetState extends State<LocalNotificationWidget> {
  final notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    final settingsAndroid = AndroidInitializationSettings('w_logo');
    final settingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) =>
            onSelectNotification(payload));

    notifications.initialize(
        InitializationSettings(android: settingsAndroid, iOS: settingsIOS),
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async => await Navigator.push(
      context,
      MaterialPageRoute(
      builder: (BuildContext context) =>
          ProfilePage(currentUser.email)),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: ListView(
      children: <Widget>[
        title('Basics'),
        RaisedButton(
          child: Text('Show notification'),
          onPressed: () => showOngoingNotification(notifications,
              title: 'Tite', body: 'Body'),
        ),
        RaisedButton(
          child: Text('Replace notification'),
          onPressed: () => showOngoingNotification(notifications,
              title: 'ReplacedTitle', body: 'ReplacedBody'),
        ),
        RaisedButton(
          child: Text('Other notification'),
          onPressed: () => showOngoingNotification(notifications,
              title: 'OtherTitle', body: 'OtherBody', id: 20),
        ),
        const SizedBox(height: 32),
        title('Feautures'),
        RaisedButton(
          child: Text('Silent notification'),
          onPressed: () => showSilentNotification(notifications,
              title: 'SilentTitle', body: 'SilentBody', id: 30),
        ),
        const SizedBox(height: 32),
        title('Cancel'),
        RaisedButton(
          child: Text('Cancel all notification'),
          onPressed: notifications.cancelAll,
        ),
      ],
    ),
  );

  Widget title(String text) => Container(
    margin: EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.title,
      textAlign: TextAlign.center,
    ),
  );
}

NotificationDetails get _noSound {
  final androidChannelSpecifics = AndroidNotificationDetails(
    'silent channel id',
    'silent channel name',
    'silent channel description',
    playSound: false,
  );
  final iOSChannelSpecifics = IOSNotificationDetails(presentSound: false);

  return NotificationDetails(android: androidChannelSpecifics, iOS: iOSChannelSpecifics);
}

Future showSilentNotification(
    FlutterLocalNotificationsPlugin notifications, {
      @required String title,
      @required String body,
      int id = 0,
    }) =>
    _showNotification(notifications,
        title: title, body: body, id: id, type: _noSound);

NotificationDetails get _ongoing {
  final androidChannelSpecifics = AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    'your channel description',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    autoCancel: false,
  );
  final iOSChannelSpecifics = IOSNotificationDetails();
  return NotificationDetails(android: androidChannelSpecifics, iOS: iOSChannelSpecifics);
}

Future showOngoingNotification(
    FlutterLocalNotificationsPlugin notifications, {
      @required String title,
      @required String body,
      int id = 0,
    }) =>
    _showNotification(notifications,
        title: title, body: body, id: id, type: _ongoing);

Future _showNotification(
    FlutterLocalNotificationsPlugin notifications, {
      @required String title,
      @required String body,
      @required NotificationDetails type,
      int id = 0,
    }) =>
    notifications.show(id, title, body, type);