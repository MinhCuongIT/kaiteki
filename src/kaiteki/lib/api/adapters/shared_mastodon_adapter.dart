import 'dart:developer';

import 'package:fediverse_objects/mastodon/account.dart';
import 'package:fediverse_objects/mastodon/emoji.dart';
import 'package:fediverse_objects/mastodon/media_attachment.dart';
import 'package:fediverse_objects/mastodon/status.dart';
import 'package:kaiteki/account_container.dart';
import 'package:kaiteki/api/adapters/fediverse_adapter.dart';
import 'package:kaiteki/api/clients/mastodon_client.dart';
import 'package:kaiteki/auth/login_functions.dart';
import 'package:kaiteki/model/auth/account_compound.dart';
import 'package:kaiteki/model/auth/account_secret.dart';
import 'package:kaiteki/model/auth/authentication_data.dart';
import 'package:kaiteki/model/auth/login_result.dart';
import 'package:kaiteki/model/fediverse/attachment.dart';
import 'package:kaiteki/model/fediverse/emoji.dart';
import 'package:kaiteki/model/fediverse/emoji_category.dart';
import 'package:kaiteki/model/fediverse/notification.dart';
import 'package:kaiteki/model/fediverse/post.dart';
import 'package:kaiteki/model/fediverse/timeline_type.dart';
import 'package:kaiteki/model/fediverse/user.dart';
import 'package:kaiteki/model/fediverse/visibility.dart';
import 'package:kaiteki/utils/extensions/iterable.dart';
import 'package:kaiteki/utils/extensions/string.dart';

part 'shared_mastodon_adapter.c.dart'; // That file contains toEntity() methods

/// A class that allows Mastodon-derivatives (e.g. Pleroma and Mastodon itself)
/// to use pre-existing code.
class SharedMastodonAdapter<T extends MastodonClient>
    extends FediverseAdapter<T> {
  SharedMastodonAdapter(T client) : super(client);

  @override
  Future<User> getUserById(String id) async {
    return toUser(await client.getAccount(id));
  }

  @override
  Future<LoginResult> login(String instance, String username, String password,
      mfaCallback, AccountContainer accounts) async {
    client.instance = instance;

    // Retrieve or create client secret
    var clientSecret = await LoginFunctions.getClientSecret(
        client, instance, accounts.getClientRepo());
    client.authenticationData = MastodonAuthenticationData();
    client.authenticationData.clientSecret = clientSecret.clientSecret;
    client.authenticationData.clientId = clientSecret.clientId;

    String accessToken;

    // Try to login and handle error
    var loginResponse = await client.login(username, password);
    accessToken = loginResponse.accessToken;

    if (loginResponse.error.isNotNullOrEmpty) {
      if (loginResponse.error != "mfa_required") {
        return LoginResult.failed(loginResponse.error);
      }

      var code = await mfaCallback.call();

      if (code == null) return LoginResult.aborted();

      // TODO add error-able TOTP screens
      // TODO make use of a while loop to make this more efficient
      var mfaResponse = await client.respondMfa(
        loginResponse.mfaToken,
        int.parse(code),
      );

      if (mfaResponse.error.isNotNullOrEmpty) {
        return LoginResult.failed(mfaResponse.error);
      } else {
        accessToken = mfaResponse.accessToken;
      }
    }

    // Create and set account secret
    var accountSecret = new AccountSecret(instance, username, accessToken);
    client.authenticationData.accessToken = accountSecret.accessToken;

    // Check whether secrets work, and if we can get an account back
    var account = await client.verifyCredentials();
    if (account == null) {
      return LoginResult.failed("Failed to verify credentials");
    }

    var compound = AccountCompound(
      container: accounts,
      adapter: this,
      account: toUser(account),
      clientSecret: clientSecret,
      accountSecret: accountSecret,
    );
    await accounts.addCurrentAccount(compound);

    return LoginResult.successful();
  }

  @override
  Future<Post> postStatus(Post post, {Post parentPost}) {
    // TODO implement postStatus
    throw UnimplementedError();
  }

  @override
  Future<User> getMyself() async {
    var account = await client.verifyCredentials();
    return toUser(account);
  }

  @override
  Future<Iterable<Notification>> getNotifications() {
    // TODO implement getNotifications
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Post>> getStatusesOfUserById(String id) async {
    return (await client.getStatuses(id)).map((mst) => toPost(mst));
  }

  @override
  Future<Iterable<Post>> getTimeline(TimelineType type) async {
    var posts = await client.getTimeline();
    return posts.map((m) => toPost(m));
  }

  @override
  Future<User> getUser(String username, [String instance]) {
    // TODO implement getUser
    throw UnimplementedError();
  }

  @override
  Future<Iterable<EmojiCategory>> getEmojis() async {
    var emojis = await client.getCustomEmojis();
    var categories = emojis.groupBy((emoji) => emoji.category);

    return categories.entries.map((kv) {
      return EmojiCategory(kv.key, kv.value.map(toEmoji));
    });
  }
}
