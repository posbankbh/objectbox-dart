import 'dart:mirrors';

String getFilePathForType(Type type) {
  // Reflect on the type.
  ClassMirror typeMirror = reflectClass(type);

  // Get the library mirror where the type is defined.
  var libraryMirror = typeMirror.owner;

  // Get the URI of the library.
  var libraryUri = libraryMirror!.location;

  // Convert the URI to a file path.
  String filePath = Uri.decodeFull(libraryUri!.sourceUri.toString());

  return filePath;
}
