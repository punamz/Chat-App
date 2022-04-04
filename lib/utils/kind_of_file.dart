import 'package:mime/mime.dart';

const messageType = 1;
const imageType = 2;
const videoType = 3;
const fileType = 4;

int checkTypeOfFile(String path) {
  final file = lookupMimeType(path)!.split('/').first;
  if (file == 'image') {
    return imageType;
  } else if (file == 'video') {
    return videoType;
  }
  return fileType;
}
