class UserProfile {
  String? name;
  String? profileUrl;
  String? uid;

  UserProfile({
    required this.uid,
    required this.name,
    required this.profileUrl,
  });

  UserProfile.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    profileUrl = json['profileUrl'];
    uid = json['uid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['profileUrl'] = profileUrl;
    data['uid'] = uid;
    return data;
  }
}
