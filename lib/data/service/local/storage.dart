import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageService {
  StorageService();
  Directory? _docDir;

  Future get _docPath async {
    _docDir ??= await getApplicationDocumentsDirectory();
    return _docDir!.path;
  }

  Future<File> getFile(int channelId, String url, [String? fname]) async {
    final docPath = await _docPath;
    return fname != null
        ? File("$docPath/$channelId/$fname")
        : File("$docPath/$channelId/${Uri.parse(url).path.split('/').last}");
  }

  Future deleteFile() async {}
  Future deleteDirectory() async {}
}
