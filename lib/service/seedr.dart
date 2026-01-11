import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logging_service.dart';
import '../models/seedr_models.dart';

/// A Dart service for interacting with the Seedr API.
class Seedr {
  String? username;
  String? password;
  String? token;
  String? rft;
  String? devc;
  String? usc;
  final LoggingService? logger;

  /// Creates a new instance of the Seedr service.
  Seedr({this.logger});

  void _log(
    String method,
    String url, {
    int? statusCode,
    String? requestBody,
    String? responseBody,
  }) {
    logger?.addLog(
      method: method,
      url: url,
      statusCode: statusCode,
      requestBody: requestBody,
      responseBody: responseBody,
    );
  }

  /// Authenticates with Seedr using username and password credentials.
  Future<String> login(String username, String password) async {
    this.username = username;

    var url = 'https://www.seedr.cc/oauth_test/token.php';
    var fields = {
      'grant_type': 'password',
      'client_id': 'seedr_chrome',
      'type': 'login',
      'username': username,
      'password': password,
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Login',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    var jsonData = json.decode(responseData);
    if (jsonData['error'] != null) {
      throw Exception(
        '${jsonData['error']}: ${jsonData['error_description'] ?? 'Unknown error'}',
      );
    }

    token = jsonData['access_token'];
    rft = jsonData['refresh_token'];

    // Safety check just in case access_token is missing but no 'error' field
    if (token == null)
      throw Exception('Login failed: No access token received.');

    return token!;
  }

  /// Retrieves a device code and user code for device-based authentication.
  Future<String> getDeviceCode() async {
    var url = 'https://www.seedr.cc/oauth_test/device.php';
    var response = await http.get(Uri.parse(url));
    _log(
      'GET Device Code',
      url,
      statusCode: response.statusCode,
      responseBody: response.body,
    );

    var data = json.decode(response.body);
    devc = data['device_code'];
    return data['user_code'];
  }

  /// Retrieves an access token using a device code.
  Future<String> getToken(String deviceCode) async {
    var url = 'https://www.seedr.cc/oauth_test/token.php';
    var fields = {
      'grant_type': 'device_code',
      'client_id': 'seedr_chrome',
      'device_code': deviceCode,
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Get Token',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    var data = json.decode(responseData);
    token = data['access_token'];
    return token!;
  }

  /// Adds a torrent to Seedr using a magnet link.
  Future<Map<String, dynamic>> addMagnet(String magnet) async {
    var url = 'https://www.seedr.cc/oauth_test/resource.php';
    var fields = {
      'access_token': token!,
      'func': 'add_torrent',
      'torrent_magnet': magnet,
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Add Magnet',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    return json.decode(responseData);
  }

  /// Retrieves the contents of a specific folder or the root folder.
  Future<SeedrFolderResponse> getFolderContents([int? folderId]) async {
    var url = folderId == null
        ? 'https://www.seedr.cc/api/folder?access_token=$token'
        : 'https://www.seedr.cc/api/folder/$folderId?access_token=$token';

    var response = await http.get(Uri.parse(url));
    // _log(
    //   'GET',
    //   url,
    //   statusCode: response.statusCode,
    //   responseBody: response.body,
    // );

    return SeedrFolderResponse.fromJson(json.decode(response.body));
  }

  /// Fetches information about a specific file by its ID.
  Future<SeedrFileDetails> getFile(int folderFileId) async {
    var url = 'https://www.seedr.cc/oauth_test/resource.php';
    var fields = {
      'access_token': token ?? '',
      'func': 'fetch_file',
      'folder_file_id': folderFileId.toString(),
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Fetch File',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    return SeedrFileDetails.fromJson(json.decode(responseData));
  }

  /// Deletes a file from your Seedr account.
  Future<dynamic> deleteFile(dynamic fileId) async {
    var url = 'https://www.seedr.cc/oauth_test/resource.php';
    var fields = {
      'access_token': token ?? '',
      'func': 'delete',
      'delete_arr': json.encode([
        {
          'type': 'file',
          'id': fileId is String ? (int.tryParse(fileId) ?? fileId) : fileId,
        },
      ]),
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Delete File',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    return json.decode(responseData);
  }

  /// Deletes a folder from your Seedr account.
  Future<dynamic> deleteFolder(dynamic folderId) async {
    var url = 'https://www.seedr.cc/oauth_test/resource.php';
    var fields = {
      'access_token': token ?? '',
      'func': 'delete',
      'delete_arr': json.encode([
        {
          'type': 'folder',
          'id': folderId is String
              ? (int.tryParse(folderId) ?? folderId)
              : folderId,
        },
      ]),
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Delete Folder',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    return json.decode(responseData);
  }

  /// Deletes a torrent from your Seedr account.
  Future<dynamic> deleteTorrent(dynamic torrentId) async {
    var url = 'https://www.seedr.cc/oauth_test/resource.php';
    var fields = {
      'access_token': token ?? '',
      'func': 'delete',
      'delete_arr': json.encode([
        {
          'type': 'torrent',
          'id': torrentId is String
              ? (int.tryParse(torrentId) ?? torrentId)
              : torrentId,
        },
      ]),
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Delete Torrent',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    return json.decode(responseData);
  }

  /// Creates an archive from a folder.
  Future<SeedrArchiveResponse> createArchive(dynamic folderId) async {
    var url = 'https://www.seedr.cc/oauth_test/resource.php';
    var fields = {
      'access_token': token ?? '',
      'func': 'create_empty_archive',
      'archive_arr': json.encode([
        {
          'type': 'folder',
          'id': folderId is String
              ? (int.tryParse(folderId) ?? folderId)
              : folderId,
        },
      ]),
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    _log(
      'POST Create Archive',
      url,
      statusCode: response.statusCode,
      requestBody: fields.toString(),
      responseBody: responseData,
    );

    return SeedrArchiveResponse.fromJson(json.decode(responseData));
  }
}
