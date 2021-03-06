import 'package:json_annotation/json_annotation.dart';

part 'account_secret.g.dart';

@JsonSerializable()
class AccountSecret {
  final String instance;

  @JsonKey(name: "user")
  final String username;

  @JsonKey(name: "token")
  final String accessToken;

  const AccountSecret(this.instance, this.username, this.accessToken) :
    assert(instance != null),
    assert(username != null),
    assert(accessToken != null);

  factory AccountSecret.fromJson(Map<String, dynamic> json) => _$AccountSecretFromJson(json);
  Map<String, dynamic> toJson() => _$AccountSecretToJson(this);
}