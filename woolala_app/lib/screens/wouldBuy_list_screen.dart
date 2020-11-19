import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:woolala_app/main.dart';
import 'dart:convert';
import 'package:woolala_app/models/post.dart';
import 'package:woolala_app/screens/login_screen.dart';
import 'package:woolala_app/screens/homepage_screen.dart';
import 'package:woolala_app/screens/profile_screen.dart';
import 'package:woolala_app/widgets/bottom_nav.dart';
import 'package:woolala_app/screens/following_list_screen.dart';

//Create Stateful Widget
class WouldBuyListScreen extends StatefulWidget {
  final String postID;
  WouldBuyListScreen(this.postID);
  @override
  _WouldBuyListScreenState createState() => _WouldBuyListScreenState();
}

// Will be used to get info about the post
Future<List> getPotentialBuyers(String id) async {
  http.Response res = await http.get(domain + '/getPostInfo/' + id);
  Map info = jsonDecode(res.body.toString());
  print(Post.fromJSON(info).WouldBuy);
  return Post.fromJSON(info).WouldBuy;
}

class _WouldBuyListScreenState extends State<WouldBuyListScreen> {
  //Lists to build the ListView
  List currentPost;
  List buyerList = new List();
  List buyerEmailList = new List();
  List buyerUserNameList = new List();

  //Build the list Asynchronously
  listbuilder() async {
    //Get the list of WouldBuy of the Post
    currentPost = await getPotentialBuyers(widget.postID);

    //Go through the Follower List of userIDs and grab their profileName, email, and userName
    for (int i = 0; i < currentPost.length; i++) {
      String tempProfileName = await getProfileName(currentPost[i]);
      String tempUserEmail = await getUserEmail(currentPost[i]);
      String tempUserName = await getUserName(currentPost[i]);
      //Add each to their respective Lists
      buyerList.add(tempProfileName);
      buyerEmailList.add(tempUserEmail);
      buyerUserNameList.add(tempUserName);
    }
    return buyerList;
  }
  //Build the list using a Futurebuilder for Async
  Widget _buildList() {
    return FutureBuilder(
      future: listbuilder(),
      builder: (context, snapshot) {
        //Make sure the snapshot is valid without errors
        if (snapshot.hasData) {
          return ListView.builder(
            key: ValueKey("ListView"),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: buyerList.length,
            itemBuilder: (BuildContext context, int index) {
              return new ListTile(
                //Create the circular avatar for the user
                leading: CircleAvatar(
                  child: Text(buyerList[index][0]),
                ),
                title: Text(buyerList[index]),
                subtitle: Text(buyerUserNameList[index]),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              ProfilePage(buyerEmailList[index])));
                },
              );
            },
          );
        } else if (snapshot.hasError) {
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
              onPressed: () =>
              //(Navigator.pushReplacementNamed(context, '/profile'))
              (Navigator.pop(context))),
          title: Text("Followers"),
          actions: <Widget>[]),
      body: ListView(padding: const EdgeInsets.all(8), children: <Widget>[
        _buildList(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          bottomBar.switchPage(index, context);
        },
        items: bottomBar.bottom_items,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
