import 'dart:convert';

import 'package:fediverse_objects/misskey/error.dart';
import 'package:fediverse_objects/misskey/meta.dart';
import 'package:fediverse_objects/misskey/note.dart';
import 'package:fediverse_objects/misskey/pages/page.dart';
import 'package:fediverse_objects/misskey/user.dart';
import 'package:http/http.dart';
import 'package:kaiteki/api/api_type.dart';
import 'package:kaiteki/api/clients/fediverse_client_base.dart';
import 'package:kaiteki/api/exceptions/misskey_exception.dart';
import 'package:kaiteki/api/requests/misskey/sign_in.dart';
import 'package:kaiteki/api/requests/misskey/timeline.dart';
import 'package:kaiteki/api/responses/misskey/create_app_response.dart';
import 'package:kaiteki/api/responses/misskey/generate_session_response.dart';
import 'package:kaiteki/api/responses/misskey/signin_response.dart';
import 'package:kaiteki/api/responses/misskey/userkey_response.dart';
import 'package:kaiteki/model/auth/authentication_data.dart';
import 'package:kaiteki/model/http_method.dart';
import 'package:kaiteki/utils/logger.dart';
import 'package:kaiteki/utils/utils.dart';

class MisskeyClient extends FediverseClientBase<MisskeyAuthenticationData> {
  @override
  ApiType get type => ApiType.Misskey;

  Future<MisskeyCreateAppResponse> createApp(
      String name, String description, List<String> permissions,
      {String callbackUrl}) async {
    return await sendJsonRequest(HttpMethod.POST, "api/app/create",
        (json) => MisskeyCreateAppResponse.fromJson(json),
        body: {
          "name": name,
          "description": description,
          "permission": permissions,
          "callbackUrl": callbackUrl
        });
  }

  Future<MisskeyGenerateSessionResponse> generateSession(
      String appSecret) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "/api/auth/session/generate",
      (j) => MisskeyGenerateSessionResponse.fromJson(j),
      body: {"appSecret": appSecret},
    );
  }

  Future<MisskeyPage> getPage(String username, String name) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/pages/show",
      (json) => MisskeyPage.fromJson(json),
      body: {
        "username": username,
        "name": name,
      },
    );
  }

  Future<MisskeyUserkeyResponse> userkey(String appSecret, String token) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/auth/session/userkey",
      (json) => MisskeyUserkeyResponse.fromJson(json),
      body: {"appSecret": appSecret, "token": token},
    );
  }

  Future<MisskeyUser> showUser(String userId) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/users/show",
      (json) => MisskeyUser.fromJson(json),
      body: {"userId": userId},
    );
  }

  Future<MisskeyUser> showUserByName(String username, [String instance]) async {
    var body = {"username": username};

    if (body.containsKey(instance)) body["instance"] = instance;

    return await sendJsonRequest(HttpMethod.POST, "api/users/show",
        (json) => MisskeyUser.fromJson(json));
  }

  Future<Iterable<MisskeyNote>> showUserNotes(
    String userId,
    bool excludeNsfw,
    Iterable<String> fileTypes,
  ) async {
    return await sendJsonRequestMultiple(
      HttpMethod.POST,
      "api/users/notes",
      (json) => MisskeyNote.fromJson(json),
      body: {
        "userId": userId,
        "fileType": fileTypes,
        "excludeNsfw": excludeNsfw,
      },
    );
  }

  Future<MisskeySignInResponse> signIn(MisskeySignInRequest request) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/signin",
      (json) => MisskeySignInResponse.fromJson(json),
      body: request,
    );
  }

  Future<Iterable<MisskeyNote>> getTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return await sendJsonRequestMultiple(
      HttpMethod.POST,
      "api/notes/timeline",
      (json) => MisskeyNote.fromJson(json),
      body: request,
    );
  }

  Future<Iterable<MisskeyNote>> getLocalTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return await sendJsonRequestMultiple(
      HttpMethod.POST,
      "api/notes/local-timeline",
      (json) => MisskeyNote.fromJson(json),
      body: request,
    );
  }

  Future<Iterable<MisskeyNote>> getHybridTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return await sendJsonRequestMultiple(
      HttpMethod.POST,
      "api/notes/hybrid-timeline",
      (json) => MisskeyNote.fromJson(json),
      body: request,
    );
  }

  Future<Iterable<MisskeyNote>> getGlobalTimeline(
    MisskeyTimelineRequest request,
  ) async {
    return await sendJsonRequestMultiple(
      HttpMethod.POST,
      "api/notes/global-timeline",
      (json) => MisskeyNote.fromJson(json),
      body: request,
    );
  }

  @override
  void checkResponse(StreamedResponse response) async {
    if (Utils.isUnsuccessfulStatusCode(response.statusCode)) {
      MisskeyError mkErr;

      try {
        var body = await response.stream.bytesToString();
        var json = jsonDecode(body);
        mkErr = MisskeyError.fromJson(json["error"]);
      } catch (_) {
        Logger.warning(
          "Failed to gather Misskey error object from erroneous response.",
        );
      }

      if (mkErr != null) {
        throw MisskeyException(
          response.statusCode,
          mkErr,
        );
      }
    }

    super.checkResponse(response);
  }

  /// Gets your account information.
  Future<MisskeyUser> i() async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/i",
      (json) => MisskeyUser.fromJson(json),
      body: {},
    );
  }

  /// Reacts to the specified note.
  Future<MisskeyUser> createReaction(String noteId, String reaction) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/notes/reactions/create",
      (json) => MisskeyUser.fromJson(json),
      body: {
        "noteId": noteId,
        "reaction": reaction,
      },
    );
  }

  /// Removes the reaction from the specified note.
  Future<MisskeyUser> deleteReaction(String noteId) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/notes/reactions/delete",
      (json) => MisskeyUser.fromJson(json),
      body: {"noteId": noteId},
    );
  }

  Future<MisskeyMeta> getInstanceMeta({bool detail = false}) async {
    return await sendJsonRequest(
      HttpMethod.POST,
      "api/meta",
      (json) => MisskeyMeta.fromJson(json),
      body: {"detail": detail},
    );
  }
}
