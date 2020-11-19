class Post {
  final String ID;
  final String UserID;
  final String ImageID;
  final String Date;
  final String Description;
  final String Comments;
  final double CumulativeRating;
  final int NumRatings;
  List WouldBuy;

  Post({
    this.ID, this.UserID, this.ImageID, this.Date, this.Description, this.Comments, this.CumulativeRating, this.NumRatings, this.WouldBuy,
  });

  Post.fromJSON(Map<String, dynamic> json)
    : ID = json["ID"],
      UserID = json["UserID"],
      ImageID = json["ImageID"],
      Date = json["Date"],
      Description = json["Description"],
      Comments = json["Comments"],
      CumulativeRating = json["CumulativeRating"],
      NumRatings = json["NumRatings"],
      WouldBuy = json["WouldBuy"];

  Map<String, dynamic> toJSON() => {
    "ID" : ID,
    "UserID" : UserID,
    "ImageID" : ImageID,
    "Date" : Date,
    "Description" : Description,
    "Comments" : Comments,
    "CumulativeRating" : CumulativeRating,
    "NumRatings" : NumRatings,
    "WouldBuy" : WouldBuy,
  };
}