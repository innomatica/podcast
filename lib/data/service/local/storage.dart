import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  StorageService();
  Directory? _docDir;
  final _log = Logger("StorageService");

  Future get _docPath async {
    _docDir ??= await getApplicationDocumentsDirectory();
    return _docDir!.path;
  }

  // Future<File> getFile(int channelId, String url, [String? fname]) async {
  //   final docPath = await _docPath;
  //   return fname != null
  //       ? File("$docPath/$channelId/$fname")
  //       : File("$docPath/$channelId/${Uri.parse(url).path.split('/').last}");
  // }

  Future<File> getFile(int channelId, String fname) async =>
      File("${await _docPath}/$channelId/$fname");

  Future<bool> deleteFile(int channelId, String fname) async {
    try {
      await File("${await _docPath}/$channelId/$fname").delete();
      return true;
    } catch (e) {
      _log.severe(e.toString());
    }
    return false;
  }

  Future<bool> deleteDirectory(int channelId) async {
    await Directory("${await _docPath}/$channelId").delete(recursive: true);
    // try {
    //   await Directory("${await _docPath}/$channelId").delete(recursive: true);
    //   return true;
    // } catch (e) {
    //   _log.severe(e.toString());
    // }
    return false;
  }
}
