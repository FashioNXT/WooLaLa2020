import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:woolala_app/screens/login_screen.dart';
import 'package:woolala_app/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:io' as Io;
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:collection';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'dart:io';
import 'package:woolala_app/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:woolala_app/screens/post_screen.dart';
import 'package:woolala_app/screens/profile_screen.dart';
import 'package:woolala_app/screens/search_screen.dart';
import 'package:woolala_app/screens/notifications.dart';
import 'package:woolala_app/widgets/bottom_nav.dart';


AudioPlayer advancedPlayer;

String domain = "http://10.0.2.2:5000";

Widget starSlider(String postID) =>
    RatingBar(
      initialRating: 2.5,
      minRating: 0,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      unratedColor: Colors.black,
      itemSize: 30,
      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) =>
          Icon(
            Icons.star,
            color: Colors.blue,
          ),
      onRatingUpdate: (rating) {
        print(rating);
        //Changing rating here
        ratePost(rating, postID);
        //getFeed("cmpoaW5ja0BnbWFpbC5jb20=", "2020-10-28");
      },
    );

Future loadMusic(String sound) async {
  if (sound == "fuck") {
    advancedPlayer = await AudioCache().play("Sounds/ashfuck.mp3");
  }
  if (sound == "woolala") {
    advancedPlayer = await AudioCache().play("Sounds/woolalaAudio.mp3");
  }
}

// Will be used anytime the post is rated
Future<http.Response> ratePost(double rating, String id) {
  return http.post(
    domain + '/ratePost/' + id.toString() + '/' + rating.toString(),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode({}),
  );
}

// Will be used to make the post for the first time.
Future<http.Response> createPost(String postID, String image, String date,
    String caption, String userID, String userName) {
  return http.post(
    domain + '/insertPost',
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'postID': postID,
      'userID': userID,
      'userName': userName,
      'image': image,
      'date': date,
      'caption': caption,
      'cumulativeRating': 0,
      'numRatings': 0
    }),
  );
}

// Will be used to get info about the post
Future<List> getPost(String id) async {
  http.Response res = await http.get(domain + '/getPostInfo/' + id);
  Map info = jsonDecode(res.body.toString());
  final decodedBytes = base64Decode(info["image"]);
  var ret = [Image.memory(decodedBytes), info["caption"], info["userID"]];
  return ret;

  //DO THIS TO GET IMAGE

  // FutureBuilder(
  //   future: getPost(POSTID),
  //   builder: (context, snapshot) {
  //     if (snapshot.hasData) {
  //       return snapshot.data;
  //     } else {
  //       return CircularProgressIndicator();
  //     }
  //   },
  // );
}

Future<User> getUserFromDB(String userID) async {
  http.Response res = await http.get(domain + '/getUser/' + userID);
  Map userMap = jsonDecode(res.body.toString());
  return User.fromJSON(userMap);
}

Future<List> getFeed(String userID) async {
  http.Response res = await http.get(domain + '/getFeed/' + userID);
  return jsonDecode(res.body.toString())["postIDs"];
}

//final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class HomepageScreen extends StatefulWidget {
  final bool signedInWithGoogle;

  HomepageScreen(this.signedInWithGoogle);

  _HomepageScreenState createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  RefreshController _refreshController =
  RefreshController(initialRefresh: false);
  var rating = 0.0;
  var postID = 0.0;
  List postList = new List();

  List<String> testList = [
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
    'assets/logos/w_logo_test.png',
  ];

  List postIDs = [];
  int numToShow = 2;
  int postsPerReload = 2;

  void _getPosts() async {
    mongo.Db db = new mongo.Db.pool([
      "mongodb://Developer_1:Developer_1@woolalacluster-shard-00-00.o4vv6.mongodb.net:27017/Feed?ssl=true&replicaSet=project-shard-0&authSource=admin&retryWrites=true&w=majority",
      "mongodb://Developer_1:Developer_1@woolalacluster-shard-00-01.o4vv6.mongodb.net:27017/Feed?ssl=true&replicaSet=project-shard-0&authSource=admin&retryWrites=true&w=majority",
      "mongodb://Developer_1:Developer_1@woolalacluster-shard-00-02.o4vv6.mongodb.net:27017/Feed?ssl=true&replicaSet=project-shard-0&authSource=admin&retryWrites=true&w=majority"
    ]);
    await db.open();
    var posts = db.collection('Posts');
    List tempList = new List();
    tempList = await posts.find(mongo.where.sortBy('date')).toList();
    db.close();

    setState(() {
      postList = tempList;
    });
  }

  void sortPosts(list) {
    list.removeWhere((item) => item == "");
    list.sort((a, b) =>
    int.parse(b.substring(b.indexOf(':::') + 3)) -
        int.parse(a.substring(a.indexOf(':::') + 3)));
  }

  void _onRefresh() async {
    postIDs = await getFeed(currentUser.userID);
    sortPosts(postIDs);
    print(postIDs);
    // if failed,use refreshFailed()
    if (mounted) setState(() {});
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (numToShow + postsPerReload > postIDs.length) {
      numToShow = postIDs.length;
    } else {
      numToShow += postsPerReload;
    }

    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  @override
  initState() {
    super.initState();
    if (currentUser != null)
      getFeed(currentUser.userID).then((list) {
        postIDs = list;
        sortPosts(postIDs);
        print(postIDs);
        setState(() {});
      });
  }

  bool showStars = false;

  Widget card(String postID) {
    return FutureBuilder(
      future: getPost(postID),
      builder: (context, postInfo) {
        if (postInfo.hasData) {
          return FutureBuilder(
              future: getUserFromDB(postInfo.data[2]),
              builder: (context, userInfo) {
                if (userInfo.hasData) {
                  return Column(children: <Widget>[
                    Container(
                        margin: const EdgeInsets.all(0),
                        color: Colors.white,
                        width: double.infinity,
                        height: 35.0,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                   Padding(
                                            child: userInfo.data.createProfileAvatar(
                                            radius: 15.0, font: 18.0),
                                            padding: EdgeInsets.all(5)
                                        ),
                                    GestureDetector(
                                            onTap: () =>
                                            {
                                              Navigator.push(context, MaterialPageRoute(
                                                  builder: (BuildContext context) =>
                                                      ProfilePage(userInfo.data.email)))
                                            },
                                            child: Padding(
                                                padding: EdgeInsets.all(5),
                                                child: Text(userInfo.data.profileName,
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                        color: Colors.black, fontSize: 16
                                                    )
                                                )
                                            )
                                    ),
                                ],
                              ),
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.more_vert)
                              )
                            ],
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      )
                    ),
                postInfo.data[0],
                Container(
                alignment: Alignment(-1.0, 0.0),
                child: Padding(
                padding: EdgeInsets.all(5),
                child: Text(postInfo.data[1],
                textAlign: TextAlign.left))),
                Center(child: starSlider(postID)),
                Container(
                margin: const EdgeInsets.all(8),
                color: Colors.grey,
                width: double.infinity,
                height: 1,
                ),
                ]);
                } else {
                return CircularProgressIndicator();
                }
              });
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    BottomNav bottomBar = BottomNav(context);
    bottomBar.currentIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WooLaLa',
          style: TextStyle(fontSize: 25),
          textAlign: TextAlign.center,
        ),
        key: ValueKey("homepage"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            key: ValueKey("Search"),
            color: Colors.white,
            onPressed: () =>
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchPage())),
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => startSignOut(context),
          )
        ],
      ),
      body: Center(
        child: postIDs.length > 0
            ? SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: ClassicHeader(),
          footer: ClassicFooter(),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: numToShow,
              addAutomaticKeepAlives: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                // The height on this will need to be edited to match whatever height is set for the picture
                return SizedBox(
                    width: double.infinity,
                    height: 800,
                    child: card(postIDs[index]));
              }),
        )
            : CircularProgressIndicator(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          bottomBar.switchPage(index, context);
        },
        items: bottomBar.bottom_items,
        backgroundColor: Colors.blueGrey[400],
      ),
    );
  }

  void startSignOut(BuildContext context) {
    print("Sign Out");
    if (widget.signedInWithGoogle) {
      googleLogoutUser();
      Navigator.pushReplacementNamed(context, '/');
    } else {
      facebookLogoutUser();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Widget _buildPostsList() {
    _getPosts();
    print(postList);
    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: testList.length, //postList later
      itemBuilder: (BuildContext context, int index) {
        return new Image(
          image: AssetImage(testList[index]),
        );
      },
    );
  }
}

// ListView.builder(
// padding: const EdgeInsets.all(0),
// itemCount: snapshot.data.length,
// itemBuilder: (BuildContext context, int index) {
// return card(snapshot.data[index]);
// });
