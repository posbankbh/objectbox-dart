import 'dart:io';

import 'package:yaml/yaml.dart';

const _pubspecFile = 'pubspec.yaml';
const _pubspecKey = 'objectbox';

/// Config reads and holds configuration for the code generator.
///
/// Expected format in pubspec.yaml:
/// ```
/// objectbox:
///   output_dir: custom
///   # Or optionally specify lib and test folder separately.
///   # output_dir:
///   #   lib: custom
///   #   test: other
/// ```
class Config {
  final String jsonFile;
  final String codeFile;
  final String outDirLib;
  final String outDirTest;
  final List<String> classesToIgnore;

  Config({String? jsonFile, String? codeFile, String? outDirLib, String? outDirTest, this.classesToIgnore = const []})
      : jsonFile = jsonFile ?? 'objectbox-model.json',
        codeFile = codeFile ?? 'objectbox.g.dart',
        outDirLib = outDirLib ?? '',
        outDirTest = outDirTest ?? '';

  factory Config.readFromPubspec() {
    final file = File(_pubspecFile);
    if (file.existsSync()) {
      final yaml = loadYaml(file.readAsStringSync())[_pubspecKey] as YamlMap?;
      if (yaml != null) {
        late final String? outDirLib;
        late final String? outDirTest;
        List<String> classesToIgnore = [];
        final outDirYaml = yaml['output_dir'];
        final ignoreClasses = yaml['ignore_super_classes'];

        if (outDirYaml is YamlMap) {
          outDirLib = outDirYaml['lib'];
          outDirTest = outDirYaml['test'];
        } else {
          outDirLib = outDirTest = outDirYaml as String?;
        }

        if (ignoreClasses is YamlList) {
          classesToIgnore = ignoreClasses.nodes.map((e) => e.value.toString()).toList();
        }

        return Config(outDirLib: outDirLib, outDirTest: outDirTest, classesToIgnore: classesToIgnore);
      }
    }
    return Config();
  }
}
