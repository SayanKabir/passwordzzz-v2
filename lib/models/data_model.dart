
class Data {
  final int? id;
  final String Site;
  final String Username;
  final String? Password_secured;

  Data(
      {this.id,
        required this.Site,
        required this.Username,
        this.Password_secured});

  Map<String, dynamic> toMap() {
    return ({
      'id': id,
      'site': Site,
      'user': Username,
      // 'password': Encryption.encryptAES(Password_secured!),
      'password': Password_secured,
    });
  }
}
