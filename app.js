const Express = require("express");
const BodyParser = require("body-parser");
const MongoClient = require("mongodb").MongoClient;
const ObjectId = require("mongodb").ObjectID;
const CONNECTION_URL = "mongodb+srv://Developer_1:Developer_1@woolalacluster.o4vv6.mongodb.net/Feed?retryWrites=true&w=majority";
//const CONNECTION_URL = "mongodb+srv://Lead_Devloper:poQLxqdUb4c2RfvJ@woolalacluster.o4vv6.mongodb.net/Feed?retryWrites=true&w=majority";
const DATABASE_NAME = "Feed";


var app = Express();
app.use(Express.json({limit: '50mb'}));
app.use(Express.urlencoded({limit: '50mb'}));
app.use(BodyParser.json());
app.use(BodyParser.urlencoded({ extended: true }));

var database, collection;

app.listen(process.env.PORT || 5000, () => {
    MongoClient.connect(CONNECTION_URL, { useNewUrlParser: true, useUnifiedTopology: true }, (error, client) => {
        if(error) {
            throw error;
        }
        database = client.db("Feed");
        collection = database.collection("Posts");
        userCollection = database.collection("Users");
        console.log("Connected to `" + DATABASE_NAME + "`!");
    });
});


app.post("/insertPost", (request, response) => {
    collection.insertOne(request.body, (error, result) => {
        if(error) {
            return response.status(500).send(error);
        }
        response.send(result.result);
    });
    var userID = request.body.userID;
    var postID = request.body.postID;
    var newVal = { $push: { postIDs: postID }};
    userCollection.updateOne({"userID":userID}, newVal, function(err, res) {
      console.log("Post Added");
    });
});

//create a user
app.post("/insertUser", (request, response) => {
    userCollection.insertOne(request.body, (error, result) => {
        if(error) {
            return response.status(500).send(error);
        }
        response.send(result.result);
    });
});

app.post("/ratePost/:id/:rating", (request, response) => {
  collection.findOne({"postID":request.params.id}, function(err, document) {
  var newNumRatings = 1 + document.numRatings;
  var newCumulativeRating = parseInt(request.params.rating) + document.cumulativeRating;
  console.log(newNumRatings);
  console.log(newCumulativeRating);
  var newvalues = { $set: {numRatings: newNumRatings, cumulativeRating: newCumulativeRating } };
  collection.updateOne({"postID":request.params.id}, newvalues, function(err, res) {

  console.log("1 document updated");
    });
  });
});


app.post("/updateUserBio/:id/:bio", (request, response) => {
  var newBio = { $set: {"bio": request.params.bio} };
  userCollection.updateOne({"userID":request.params.id}, newBio, function(err, res){
    if (err) throw err;
    console.log("USER: " + request.params.id + "\nNew Bio: " + request.params.bio);
    response.send(res);
  });
});

app.post("/updateUserName/:id/:name", (request, response) => {
  var newName = { $set: {"userName": request.params.name} };
  userCollection.updateOne({"userID":request.params.id}, newName, function(err, res){
    if (err) throw err;
    console.log("USER: " + request.params.id + "\nNew Name: " + request.params.name);
    response.send(res);
  });
});

app.post("/updateUserProfileName/:id/:name", (request, response) => {
  var newName = { $set: {"profileName": request.params.name} };
  userCollection.updateOne({"userID":request.params.id}, newName, function(err, res){
    if (err) throw err;
    console.log("New Name: " + request.params.name);
    response.send(res);
  });
});

app.post("/updateUserPrivacy/:id/:private", (request, response) => {
  var privacyBool = request.params.private == 'true';
  var newPrivacy = { $set: {"private": privacyBool}};
  userCollection.updateOne({"userID":request.params.id}, newPrivacy, function(err, res){
    if (err) throw err;
    console.log("Account Privacy: " + privacyBool);
    response.send(res);
  });
});

app.post("/updateUserProfilePic/:id/:image64str", (request, response) => {
  console.log(request.params.image64str);
  var newPic = { $set: {"profilePic": request.params.image64str} };
 console.log(newPic);
  userCollection.updateOne({"userID":request.params.id}, newPic, function(err, res){
    if (err) throw err;
    console.log("Profie Picture changed!");
    response.send(res);
  });
});

app.get("/getPostInfo/:id", (request, response) => {
    collection.findOne({"postID":request.params.id}, function(err, document) {
    response.send(document);
    });
});

app.get("/doesUserExist/:email", (request, response) => {
    userCollection.findOne({"email":request.params.email}, function(err, document) {
      if(document)
      {
        //console.log(document);
        response.send(document);
        }
      else
      {
      response.send(err);
      }
    });
});

app.get("/getUser/:userID", (request, response) => {
    userCollection.findOne({"userID":request.params.userID}, function(err, document) {
      if(document)
        console.log("Found user: " + request.params.userID);
        response.send(document);
    });
});

app.get("/getUserByUserName/:userName", (request, response) => {
    userCollection.findOne({"userName":request.params.userName}, function(err, document) {
      if(document)
        console.log("Found user! with UserName: " + request.params.userName);
        response.send(document);
    });
});

app.get("/getAllUsers", (request, response) => {
    userCollection.find({}).toArray(function(err, documents) {
        if(documents)
            //console.log("Retrieved all Users");
            response.send(documents);
            //console.log(documents);
    });
});


app.get("/getFeed/:userID", (request, response) => {
      console.log('Feed requested for user ' + request.params.userID);

      var postIDs = [];
      userCollection.findOne({"userID":request.params.userID}, function(err, document) {
        if(document)
        {
          var following = document.following;
          userCollection.find({"userID": {$in: following}}).toArray(function(err, results)
          {
              for(var i = 0; i < results.length; i++)
              {
                postIDs.push(...results[i].postIDs);
              }
              console.log(postIDs);
              response.send({"postIDs":postIDs});
          });
        }
      });

});

app.post("/follow/:you/:them", (request, response) => {
    var currentUserID = request.params.you;
    var followUserID = request.params.them;
    var updateCurrent = { $push: { following: followUserID }};
    var updateOther = { $push: { followers: currentUserID }};

    userCollection.updateOne({"userID":currentUserID}, updateCurrent, function(err, res) {
      console.log(currentUserID + " now has " + followUserID + " in their following array");
    });

    userCollection.updateOne({"userID":followUserID}, updateOther, function(err, res) {
      console.log(followUserID + " now has " + currentUserID + " in their followers array");
    });
    response.send({});
});

app.post("/unfollow/:you/:them", (request, response) => {
    var currentUserID = request.params.you;
    var unfollowUserID = request.params.them;
    var updateCurrent = { $pull: {following: unfollowUserID}};
    var updateOther = { $pull: {followers: currentUserID}};

    userCollection.updateOne({"userID":currentUserID}, updateCurrent, function(err, res) {
      console.log(currentUserID + " now does not have " + unfollowUserID + " in their following array");
    });

    userCollection.updateOne({"userID":unfollowUserID}, updateOther, function(err, res) {
      console.log(unfollowUserID + " now does not have " + currentUserID + " in their followers array");
    });
    response.send({});
});

app.get("/wouldBuyAlready/:postID/:userID", (request, response) => {
    var post = request.params.postID;
    var user = request.params.userID;

    collection.findOne({"postID":post, wouldBuy: user}, function(err, res) {
        console.log(user + "is already on the list wouldBuy for post: " + post);
    });
    response.send({});
});

app.post("/wouldBuy/:postID/:userID", (request, response) => {
    var post = request.params.postID;
    var user = request.params.userID;
    var updateWouldBuyList = { $push: {wouldBuy: user}};

    collection.updateOne({"postID":post}, updateWouldBuyList, function(err, res) {
        console.log(user + "has been added to the wouldBuy List for post: " + post);
    });
    response.send({});
});