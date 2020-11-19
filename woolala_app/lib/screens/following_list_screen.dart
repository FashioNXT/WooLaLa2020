import 'package:flutter/material.dart';
import 'package:woolala_app/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:woolala_app/models/user.dart';
import 'package:woolala_app/screens/profile_screen.dart';
import 'package:woolala_app/widgets/bottom_nav.dart';
import 'package:woolala_app/screens/search_screen.dart';
import 'package:woolala_app/main.dart';

//Create Stateful Widget
class FollowingListScreen extends StatefulWidget {
  final String userEmail;
  FollowingListScreen(this.userEmail);
  @override
  _FollowingListScreenState createState() => _FollowingListScreenState();
}

//Gets the profileName of the user
Future<String> getProfileName(String userID) async {
  http.Response res = await http.get(domain + "/getUser/" + userID);
  Map userMap = jsonDecode(res.body.toString());
  return User.fromJSON(userMap).profileName;
}
//Gets the email of the user
Future<String> getUserEmail(String userID) async {
  http.Response res = await http.get(domain + "/getUser/" + userID);
  Map userMap = jsonDecode(res.body.toString());
  return User.fromJSON(userMap).email;
}
//Gets the userName of the user
Future<String> getUserName(String userID) async {
  http.Response res = await http.get(domain + "/getUser/" + userID);
  Map userMap = jsonDecode(res.body.toString());
  return User.fromJSON(userMap).userName;
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  //Lists to build the ListView
  User currentProfile;
  List followingList = new List();
  List followingEmailList = new List();
  List followingUserNameList = new List();
  List followingUserIDList = new List();

  //Build the list Asynchronously
  listbuilder() async {
    //Make sure the user Exists
    currentProfile = await getDoesUserExists(widget.userEmail);
    List tempFollowingList = new List();
    tempFollowingList = currentProfile.following;

    //Go through the Follower List of userIDs and grab their profileName, email, and userName
    for (int i = 0; i < tempFollowingList.length; i++) {
      String tempProfileName = await getProfileName(tempFollowingList[i]);
      String tempUserEmail = await getUserEmail(tempFollowingList[i]);
      String tempUserName = await getUserName(tempFollowingList[i]);
      followingList.add(tempProfileName);
      followingEmailList.add(tempUserEmail);
      followingUserNameList.add(tempUserName);
    }
    return followingList;
  }

  Widget _buildList() {
    return FutureBuilder(
      future: listbuilder(),
      builder: (context, snapshot) {
        //Check to make sure the snapshot has data and check if user is viewing their own profile
        if (snapshot.hasData && currentUser.userID == currentProfile.userID) {
          return ListView.builder(
            key: ValueKey("ListView"),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: followingList.length,
            itemBuilder: (BuildContext context, int index) {
              return new ListTile(
                leading: CircleAvatar(
                  child: Text(followingList[index][0]),
                ),
                title: Text(followingList[index]),
                subtitle: Text(followingUserNameList[index]),
                trailing: Wrap(
                  spacing: 12,
                  children: <Widget>[
                    new Container(
                      child: new IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          unfollow(currentUser.userID, followingList[index]);
                          followingList.remove(followingList[index]);
                          _buildList();
                          Navigator.pushReplacement(
                            context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation1, animation2) => FollowingListScreen(currentUser.email),
                                transitionDuration: Duration(seconds: 0),
                              )
                          );
                          },
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              ProfilePage(followingEmailList[index])));
                },
              );
            },
          );
        }
        //Check to make sure if user is viewing someone else's profile
        else if (snapshot.hasData && currentUser.userID != currentProfile.userID){
          return ListView.builder(
            key: ValueKey("ListView"),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: followingList.length,
            itemBuilder: (BuildContext context, int index) {
              return new ListTile(
                leading: CircleAvatar(
                  child: Text(followingList[index][0]),
                ),
                title: Text(followingList[index]),
                subtitle: Text(followingUserNameList[index]),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              ProfilePage(followingEmailList[index])));
                },
              );
            },
          );
        }
        else if (snapshot.hasError) {
          return Center(child: Text("No Results"));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    BottomNav bottomBar = BottomNav(context);
    return Scaffold(
      appBar: AppBar(
          leading: BackButton(
              color: Colors.white,
              onPressed: () {
                //(Navigator.pushReplacementNamed(context, '/profile'))
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => ProfilePage(currentProfile.email),
                      transitionDuration: Duration(seconds: 0),
                    )
                );
              }),
          title: Text("Following"),
          actions: <Widget>[]),
      body: ListView(padding: const EdgeInsets.all(8), children: <Widget>[
        _buildList(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
          onTap: (int index) {
            bottomBar.switchPage(index, context);
          },
          items: bottomBar.bottom_items),
    );
  }
}
