import 'package:build/build.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:objectbox/internal.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_gen/source_gen.dart' show InvalidGenerationSourceError;

class CodeChunks {
  /// Alias for objectbox.dart import. Prefix classes from it like '$obx.Class'.
  static String obx = "obx";

  /// Alias for internal.dart import. Prefix classes from it like '$obxInt.Class'.
  static String obxInt = "obx_int";

  /// Note: objectbox imports in generated code are aliased to avoid name
  /// collisions with entity classes.
  static String objectboxDart(ModelInfo model, List<String> imports, Pubspec? pubspec) => """
    // GENERATED CODE - DO NOT MODIFY BY HAND
    // This code was generated by ObjectBox. To update it run the generator again:
    // With a Flutter package, run `flutter pub run build_runner build`.
    // With a Dart package, run `dart run build_runner build`.
    // See also https://docs.objectbox.io/getting-started#generate-objectbox-code

    // ignore_for_file: camel_case_types, depend_on_referenced_packages
    // coverage:ignore-file

    import 'dart:typed_data';
    import 'dart:convert';

    import 'package:flat_buffers/flat_buffers.dart' as fb;
    import 'package:objectbox/internal.dart' as $obxInt; // generated code can access "internal" functionality
    import 'package:objectbox/objectbox.dart' as $obx;${pubspec?.obxFlutterImport}

    import '${sorted(imports).join("';\n import '")}';

    export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

    final entities = <$obxInt.ModelEntity>[
      ${model.entities.map(createModelEntity).join(',')}
    ];

    /// Shortcut for [Store.new] that passes [getObjectBoxModel] and for Flutter
    /// apps by default a [directory] using `defaultStoreDirectory()` from the
    /// ObjectBox Flutter library.
    ///
    /// Note: for desktop apps it is recommended to specify a unique [directory].
    /// 
    /// See [Store.new] for an explanation of all parameters.
    /// 
    /// For Flutter apps, also calls `loadObjectBoxLibraryAndroidCompat()` from
    /// the ObjectBox Flutter library to fix loading the native ObjectBox library
    /// on Android 6 and older.
    ${openStore(model, pubspec)}

    /// Returns the ObjectBox model definition for this project for use with 
    /// [Store.new].
    $obxInt.ModelDefinition getObjectBoxModel() {
      ${defineModel(model)}

      final bindings = <Type, $obxInt.EntityDefinition>{
        ${model.entities.mapIndexed((i, entity) => "${entity.name}: ${entityBinding(i, entity)}").join(",\n")}
      };

      return $obxInt.ModelDefinition(model, bindings);
    }

    ${model.entities.mapIndexed(_metaClass).join("\n")}
    """;

  /// Builds openStore method code string wrapping the [Store] constructor.
  ///
  /// If the ObjectBox Flutter dependency is detected in [pubspec], will
  /// add its compat loading for the Android library and use its default
  /// directory detection. Also the method will become async.
  static String openStore(ModelInfo model, Pubspec? pubspec) {
    final obxFlutter = pubspec?.hasObxFlutterDependency ?? false;
    return '''${obxFlutter ? 'Future<$obx.Store>' : '$obx.Store'} openStore(
        {String? directory,
          int? maxDBSizeInKB,
          int? maxDataSizeInKB,
          int? fileMode,
          int? maxReaders,
          bool queriesCaseSensitiveDefault = true,
          String? macosApplicationGroup})${obxFlutter ? ' async' : ''} {
        ${obxFlutter ? 'await loadObjectBoxLibraryAndroidCompat();' : ''}
        return $obx.Store(getObjectBoxModel(),
            directory: directory${obxFlutter ? ' ?? (await defaultStoreDirectory()).path' : ''},
            maxDBSizeInKB: maxDBSizeInKB,
            maxDataSizeInKB: maxDataSizeInKB,
            fileMode: fileMode,
            maxReaders: maxReaders,
            queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
            macosApplicationGroup: macosApplicationGroup);
    }''';
  }

  static List<T> sorted<T>(List<T> list) {
    list.sort();
    return list;
  }

  static String defineModel(ModelInfo model) {
    return '''
    final model = $obxInt.ModelInfo(
      entities: entities,
      lastEntityId: ${createIdUid(model.lastEntityId)},
      lastIndexId: ${createIdUid(model.lastIndexId)},
      lastRelationId: ${createIdUid(model.lastRelationId)},
      lastSequenceId: ${createIdUid(model.lastSequenceId)},
      retiredEntityUids: const ${model.retiredEntityUids},
      retiredIndexUids: const ${model.retiredIndexUids},
      retiredPropertyUids: const ${model.retiredPropertyUids},
      retiredRelationUids: const ${model.retiredRelationUids},
      modelVersion: ${model.modelVersion},
      modelVersionParserMinimum: ${model.modelVersionParserMinimum},
      version: ${model.version});
    ''';
  }

  static String createIdUid(IdUid value) {
    return 'const $obxInt.IdUid(${value.id}, ${value.uid})';
  }

  static String createModelEntity(ModelEntity entity) {
    return '''
    $obxInt.ModelEntity(
      id: ${createIdUid(entity.id)},
      name: '${entity.name}',
      lastPropertyId: ${createIdUid(entity.lastPropertyId)},
      flags: ${entity.flags},
      properties: <$obxInt.ModelProperty>[
        ${entity.properties.map(createModelProperty).join(',')}
      ],
      relations: <$obxInt.ModelRelation>[
        ${entity.relations.map(createModelRelation).join(',')}
      ],
      backlinks: <$obxInt.ModelBacklink>[
        ${entity.backlinks.map(createModelBacklink).join(',')}
      ]
    )
    ''';
  }

  static String createModelProperty(ModelProperty property) {
    var additionalArgs = '';
    if (property.indexId != null && !property.indexId!.isEmpty) {
      additionalArgs += ', indexId: ${createIdUid(property.indexId!)}';
    }
    if (property.relationTarget != null && property.relationTarget!.isNotEmpty) {
      additionalArgs += ", relationTarget: '${property.relationTarget!}'";
    }
    return '''
    $obxInt.ModelProperty(
      id: ${createIdUid(property.id)},
      name: '${property.name}',
      type: ${property.type},
      flags: ${property.flags}
      $additionalArgs
    )
    ''';
  }

  static String createModelRelation(ModelRelation relation) {
    return '''
    $obxInt.ModelRelation(
      id: ${createIdUid(relation.id)},
      name: '${relation.name}',
      targetId: ${createIdUid(relation.targetId)}
    )
    ''';
  }

  static String createModelBacklink(ModelBacklink backlink) {
    return '''
    $obxInt.ModelBacklink(
      name: '${backlink.name}',
      srcEntity: '${backlink.srcEntity}',
      srcField: '${backlink.srcField}'
    )
    ''';
  }

  static String entityBinding(int i, ModelEntity entity) {
    final name = entity.name;
    return '''
      $obxInt.EntityDefinition<$name>(
        model: entities[$i],
        toOneRelations: ($name object) => ${toOneRelations(entity)},
        toManyRelations: ($name object) => ${toManyRelations(entity)},
        getId: ($name object) => object.${propertyFieldName(entity.idProperty)},
        setId: ($name object, int id) ${setId(entity)},
        objectToFB: ${objectToFB(entity)},
        objectFromFB: ${objectFromFB(entity)}
      )
      ''';
  }

  static String propertyFieldName(ModelProperty property) {
    if (property.isRelation) {
      if (!property.name.endsWith('Id')) {
        throw ArgumentError.value(property.name, 'property.name', 'Relation property name must end with "Id"');
      }

      return property.name.substring(0, property.name.length - 2);
    }

    return property.name;
  }

  static String setId(ModelEntity entity) {
    if (!entity.idProperty.fieldIsReadOnly) {
      return '{object.${propertyFieldName(entity.idProperty)} = id;}';
    }
    // Note: this is a special case handling read-only IDs with assignable=true.
    // Such ID must already be set, i.e. it could not have been assigned.
    return '''{
      if (object.${propertyFieldName(entity.idProperty)} != id) {
        throw ArgumentError('Field ${entity.name}.${propertyFieldName(entity.idProperty)} is read-only '
        '(final or getter-only) and it was declared to be self-assigned. '
        'However, the currently inserted object (.${propertyFieldName(entity.idProperty)}=\${object.${propertyFieldName(entity.idProperty)}}) '
        "doesn't match the inserted ID (ID \$id). "
        'You must assign an ID before calling [box.put()].');
      }
    }''';
  }

  static String fieldDefaultValue(ModelProperty p) {
    if (p.isEnum) return p.enumDefaultValue == null ? (p.fieldIsNullable ? 'null' : '') : "'${p.enumDefaultValue}'";

    switch (p.fieldType) {
      case 'int':
      case 'double':
        return '0';
      case 'bool':
        return 'false';
      case 'String':
        return "''";
      case 'List':
        return '[]';
      case 'Int8List':
        return 'Int8List(0)';
      case 'Uint8List':
        return 'Uint8List(0)';
      case 'Int16List':
        return 'Int16List(0)';
      case 'Uint16List':
        return 'Uint16List(0)';
      case 'Int32List':
        return 'Int32List(0)';
      case 'Uint32List':
        return 'Uint32List(0)';
      case 'Int64List':
        return 'Int64List(0)';
      case 'Uint64List':
        return 'Uint64List(0)';
      case 'Float32List':
        return 'Float32List(0)';
      case 'Float64List':
        return 'Float64List(0)';
      default:
        throw InvalidGenerationSourceError('Cannot figure out default value for field: ${p.fieldType} ${p.name}');
    }
  }

  static String propertyFieldAccess(ModelProperty p, String suffixIfNullable) {
    return propertyFieldName(p) + (p.fieldIsNullable ? suffixIfNullable : '');
  }

  static int propertyFlatBuffersSlot(ModelProperty property) => property.id.id - 1;

  static int propertyFlatBuffersvTableOffset(ModelProperty property) => 4 + 2 * propertyFlatBuffersSlot(property);

  static final _propertyFlatBuffersType = <int, String>{
    OBXPropertyType.Bool: 'Bool',
    OBXPropertyType.Byte: 'Int8',
    OBXPropertyType.Short: 'Int16',
    OBXPropertyType.Char: 'Uint16',
    OBXPropertyType.Int: 'Int32',
    OBXPropertyType.Long: 'Int64',
    OBXPropertyType.Float: 'Float32',
    OBXPropertyType.Double: 'Float64',
    OBXPropertyType.String: 'String',
    OBXPropertyType.Date: 'Int64',
    OBXPropertyType.Relation: 'Int64',
    OBXPropertyType.DateNano: 'Int64',
  };

  static String objectToFB(ModelEntity entity) {
    // prepare properties that must be defined before the FB table is started
    final offsets = <int, String>{};
    final offsetsCode = entity.properties.map((ModelProperty p) {
      final offsetVar = '${propertyFieldName(p)}Offset';
      var fieldName = 'object.${propertyFieldName(p)}';
      offsets[p.id.id] = offsetVar; // see default case in the switch

      var assignment = 'final $offsetVar = ';
      if (p.fieldIsNullable) {
        assignment += '$fieldName == null ? null : ';
        fieldName += '!';
      }
      switch (p.type) {
        case OBXPropertyType.String:
          if (p.isEnum) {
            return '$assignment fbb.writeString($fieldName.name);';
          } else if (p.isMap) {
            return '$assignment fbb.writeString(jsonEncode($fieldName));';
          } else {
            return '$assignment fbb.writeString($fieldName);';
          }
        case OBXPropertyType.StringVector:
          return '$assignment fbb.writeList($fieldName.map(fbb.writeString).toList(growable: false));';
        case OBXPropertyType.ByteVector:
          return '$assignment fbb.writeListInt8($fieldName);';
        case OBXPropertyType.CharVector:
        case OBXPropertyType.ShortVector:
          return '$assignment fbb.writeListInt16($fieldName);';
        case OBXPropertyType.IntVector:
          return '$assignment fbb.writeListInt32($fieldName);';
        case OBXPropertyType.LongVector:
          return '$assignment fbb.writeListInt64($fieldName);';
        case OBXPropertyType.FloatVector:
          return '$assignment fbb.writeListFloat32($fieldName);';
        case OBXPropertyType.DoubleVector:
          return '$assignment fbb.writeListFloat64($fieldName);';
        default:
          offsets.remove(p.id.id);
          return null;
      }
    }).where((s) => s != null);

    // prepare the remainder of the properties, including those with offsets
    final propsCode = entity.properties.map((ModelProperty p) {
      final fbField = propertyFlatBuffersSlot(p);
      if (offsets.containsKey(p.id.id)) {
        return 'fbb.addOffset($fbField, ${offsets[p.id.id]});';
      } else {
        var accessorSuffix = '';
        if (p == entity.idProperty) {
          // ID must always be present in the flatbuffer
          if (p.fieldIsNullable) accessorSuffix = ' ?? 0';
        } else if (p.isRelation) {
          accessorSuffix = '.targetId';
        } else if (p.fieldType == 'DateTime') {
          if (p.type == OBXPropertyType.Date) {
            if (p.fieldIsNullable) accessorSuffix = '?';
            accessorSuffix += '.millisecondsSinceEpoch';
          } else if (p.type == OBXPropertyType.DateNano) {
            if (p.fieldIsNullable) {
              accessorSuffix = ' == null ? null : object.${propertyFieldName(p)}!';
            }
            accessorSuffix += '.microsecondsSinceEpoch * 1000';
          }
        }
        return 'fbb.add${_propertyFlatBuffersType[p.type]}($fbField, object.${propertyFieldName(p)}$accessorSuffix);';
      }
    });

    return '''(${entity.name} object, fb.Builder fbb) {
      ${offsetsCode.join('\n')}
      fbb.startTable(${entity.lastPropertyId.id + 1});
      ${propsCode.join('\n')}
      fbb.finish(fbb.endTable());
      return object.${propertyFieldAccess(entity.idProperty, ' ?? 0')};
    }''';
  }

  /// Builds a code string for reading a field.
  ///
  /// Depending on the field being nullable uses FlatBuffers
  /// `.vTableGetNullable` or `.vTableGet` method.
  ///
  /// If the field is non-null will pass [defaultValue] to `.vTableGet`. If not
  /// provided [fieldDefaultValue].
  ///
  /// If [castTo] is given, adds a cast code string (e.g. `as Type?` or
  /// `as Type`).
  static String readFieldCodeString(ModelProperty p, String readerCode, {String? defaultValue, String? castTo}) {
    final buf = StringBuffer();
    final offset = propertyFlatBuffersvTableOffset(p);
    buf.write("const $readerCode");
    if (p.fieldIsNullable) {
      buf.write('.vTableGetNullable(buffer, rootOffset, $offset)');
    } else {
      buf.write('.vTableGet(buffer, rootOffset, $offset, ${defaultValue ?? fieldDefaultValue(p)})');
    }
    if (castTo != null) {
      // "as Type" or "as Type?"
      buf.write("as $castTo");
      if (p.fieldIsNullable) {
        buf.write("?");
      }
    }
    return buf.toString();
  }

  /// Builds a code string for reading a field with a FlatBuffers ListReader.
  ///
  /// E.g. uses `fb.ListReader<int>(fb.Int8Reader(), lazy: false)` as reader
  /// code string.
  static String readListCodeString(ModelProperty p, String itemType, int obxPropertyType, {String? defaultValue, String? castTo}) {
    return readFieldCodeString(p, "fb.ListReader<$itemType>(fb.${_propertyFlatBuffersType[obxPropertyType]}Reader(), lazy: false)",
        defaultValue: defaultValue, castTo: castTo);
  }

  static String objectFromFB(ModelEntity entity) {
    // collect code for the template at the end of this function
    final constructorLines = <String>[]; // used as constructor arguments
    final cascadeLines = <String>[]; // used with cascade operator (..sth = val)
    final preLines = <String>[]; // code ran before the object is initialized
    final postLines = <String>[]; // code ran after the object is initialized

    // Prepare a "reader" for each field. As a side-effect, create a map from
    // property to its index in entity.properties.
    final fieldIndexes = <String, int>{};
    final fieldReaders = entity.properties.mapIndexed((int index, ModelProperty p) {
      fieldIndexes[propertyFieldName(p)] = index;

      // Special handling for DateTime fields.
      if (p.fieldType == 'DateTime') {
        final readCodeString = readFieldCodeString(p, 'fb.${_propertyFlatBuffersType[p.type]}Reader()', defaultValue: '0');
        if (p.fieldIsNullable) {
          final valueVar = '${propertyFieldName(p)}Value';
          preLines.add('final $valueVar = $readCodeString;');
          if (p.type == OBXPropertyType.Date) {
            return '$valueVar == null ? null : DateTime.fromMillisecondsSinceEpoch($valueVar)';
          } else if (p.type == OBXPropertyType.DateNano) {
            return '$valueVar == null ? null : DateTime.fromMicrosecondsSinceEpoch(($valueVar / 1000).round())';
          }
        } else {
          if (p.type == OBXPropertyType.Date) {
            return "DateTime.fromMillisecondsSinceEpoch($readCodeString)";
          } else if (p.type == OBXPropertyType.DateNano) {
            return "DateTime.fromMicrosecondsSinceEpoch(($readCodeString / 1000).round())";
          }
        }
        throw InvalidGenerationSourceError('Invalid property data type ${p.type} for a DateTime field ${entity.name}.${p.name}');
      }

      //Special for maps
      if (p.isMap) {
        final valueVar = '${propertyFieldName(p)}Value';
        final tempVar = '${propertyFieldName(p)}Temp';
        final dbValue = readFieldCodeString(p, 'fb.StringReader(asciiOptimization: true)');
        var line = 'final $tempVar = $dbValue;';
        line += '\n';
        if (p.fieldIsNullable) {
          line += 'final $valueVar = $tempVar == null ? null : jsonDecode($tempVar);';
        } else {
          line += 'final $valueVar = jsonDecode($tempVar);';
        }
        return line;
      }

      switch (p.type) {
        case OBXPropertyType.ByteVector:
          if (['Int8List', 'Uint8List'].contains(p.fieldType)) {
            // Can cast to Int8List or Uint8List as FlatBuffers internally
            // uses it, see Int8ListReader and Uint8ListReader.
            return readFieldCodeString(p, 'fb.${p.fieldType}Reader(lazy: false)', castTo: p.fieldType);
          } else {
            return readListCodeString(p, "int", OBXPropertyType.Byte);
          }
        case OBXPropertyType.CharVector:
          return readListCodeString(p, "int", OBXPropertyType.Char);
        case OBXPropertyType.ShortVector:
          // FlatBuffers has Uint16ListReader, but it does not use Uint16List
          // internally. Use implementation of objectbox package.
          if (['Int16List', 'Uint16List'].contains(p.fieldType)) {
            return readFieldCodeString(p, '$obxInt.${p.fieldType}Reader()');
          } else {
            return readListCodeString(p, "int", OBXPropertyType.Short);
          }
        case OBXPropertyType.IntVector:
          if (['Int32List', 'Uint32List'].contains(p.fieldType)) {
            // FlatBuffers has Uint32ListReader, but it does not use Uint32List
            // internally. Use implementation of objectbox package.
            return readFieldCodeString(p, '$obxInt.${p.fieldType}Reader()');
          } else {
            return readListCodeString(p, "int", OBXPropertyType.Int);
          }
        case OBXPropertyType.LongVector:
          if (['Int64List', 'Uint64List'].contains(p.fieldType)) {
            // FlatBuffers has no readers for these.
            // Use implementation of objectbox package.
            return readFieldCodeString(p, '$obxInt.${p.fieldType}Reader()');
          } else {
            return readListCodeString(p, "int", OBXPropertyType.Long);
          }
        case OBXPropertyType.FloatVector:
          if (p.fieldType == 'Float32List') {
            // FlatBuffers has Float32ListReader, but it does not use Float32List
            // internally. Use implementation of objectbox package.
            return readFieldCodeString(p, '$obxInt.Float32ListReader()');
          } else {
            return readListCodeString(p, "double", OBXPropertyType.Float);
          }
        case OBXPropertyType.DoubleVector:
          if (p.fieldType == 'Float64List') {
            // FlatBuffers has Float64ListReader, but it does not use Float64List
            // internally. Use implementation of objectbox package.
            return readFieldCodeString(p, '$obxInt.Float64ListReader()');
          } else {
            return readListCodeString(p, "double", OBXPropertyType.Double);
          }
        case OBXPropertyType.Relation:
          return readFieldCodeString(p, 'fb.${_propertyFlatBuffersType[p.type]}Reader()', defaultValue: '0');
        case OBXPropertyType.String:
          // still makes sense to keep `asciiOptimization: true`
          // `readAll` faster(6.1ms) than when false(8.1ms) on Flutter 3.0.1, Dart 2.17.1
          final dbValue = readFieldCodeString(p, 'fb.StringReader(asciiOptimization: true)');
          if (p.isEnum) {
            return '${p.enumName}.values.firstWhere((x) => x.name == $dbValue, orElse: () => ${p.enumDefaultValue == null ? null : '${p.enumName!}.${p.enumDefaultValue!}'})';
          } else {
            return dbValue;
          }
        case OBXPropertyType.StringVector:
          // still makes sense to keep `asciiOptimization: true`
          // `readAll` faster(6.1ms) than when false(8.1ms) on Flutter 3.0.1, Dart 2.17.1
          return readFieldCodeString(p, 'fb.ListReader<String>(fb.StringReader(asciiOptimization: true), lazy: false)');
        default:
          return readFieldCodeString(p, 'fb.${_propertyFlatBuffersType[p.type]}Reader()');
      }
    }).toList(growable: false);

    // try to initialize as much as possible using the constructor
    entity.constructorParams.forEachWhile((String declaration) {
      // See [EntityResolver.constructorParams()] for the format.
      final declarationParts = declaration.split(' ');
      final paramName = declarationParts[0];
      final paramType = declarationParts[1];
      final paramDartType = declarationParts[2];

      final index = fieldIndexes[paramName];
      late String paramValueCode;
      if (index != null) {
        paramValueCode = fieldReaders[index];
        if (entity.properties[index].isRelation) {
          if (paramDartType.startsWith('ToOne<')) {
            paramValueCode = '$obx.$paramDartType(targetId: $paramValueCode)';
          } else if (paramType == 'optional-named') {
            log.info('Skipping constructor parameter $paramName on '
                "'${entity.name}': the matching field is a relation but the type "
                "isn't - don't know how to initialize this parameter.");
            return true;
          }
        }
      } else if (paramDartType.startsWith('ToMany<')) {
        paramValueCode = '$obx.$paramDartType()';
      } else {
        // If we can't find a positional param, we can't use the constructor at all.
        if (paramType == 'positional' || paramType == 'required-named') {
          throw InvalidGenerationSourceError("Cannot use the default constructor of '${entity.name}': "
              "don't know how to initialize param $paramName - no such property.");
        } else if (paramType == 'optional') {
          // OK, close the constructor, the rest will be initialized separately.
          return false;
        }
        return true; // continue to the next param
      }

      // The Dart Formatter consumes a large amount of time if constructor
      // parameters are complex expressions, so add a variable for each
      // parameter instead and pass that to the constructor.
      // As the parameter name is user supplied add a suffix to avoid collision
      // with other variables of the generated method.
      final paramVar = "${paramName}Param";
      preLines.add("final $paramVar = $paramValueCode;");

      switch (paramType) {
        case 'positional':
        case 'optional':
          constructorLines.add(paramVar);
          break;
        case 'required-named':
        case 'optional-named':
          constructorLines.add('$paramName: $paramVar');
          break;
        default:
          throw InvalidGenerationSourceError('Invalid constructor parameter type - internal error');
      }

      // Good, we don't need to set this field anymore.
      // Don't remove - that would mess up indexes.
      if (index != null) fieldReaders[index] = '';

      return true;
    });

    // initialize the rest using the cascade operator
    fieldReaders.forEachIndexed((int index, String code) {
      if (code.isNotEmpty && !entity.properties[index].isRelation) {
        cascadeLines.add('..${propertyFieldName(entity.properties[index])} = $code');
      }
    });

    // add initializers for relations
    entity.properties.forEachIndexed((int index, ModelProperty p) {
      if (!p.isRelation) return;
      if (fieldReaders[index].isNotEmpty) {
        postLines.add('object.${propertyFieldName(p)}.targetId = ${fieldReaders[index]};');
      }
      postLines.add('object.${propertyFieldName(p)}.attach(store);');
    });

    postLines.addAll(entity.relations.map((ModelRelation rel) =>
        '$obxInt.InternalToManyAccess.setRelInfo<${entity.name}>(object.${rel.name}, store, ${relInfo(entity, rel)});'));

    postLines.addAll(entity.backlinks.map((ModelBacklink bl) {
      return '$obxInt.InternalToManyAccess.setRelInfo<${entity.name}>(object.${bl.name}, store, ${backlinkRelInfo(entity, bl)});';
    }));

    return '''($obx.Store store, ByteData fbData) {
      final buffer = fb.BufferContext(fbData);
      final rootOffset = buffer.derefObject(0);
      ${preLines.join('\n')}
      final object = ${entity.name}(${constructorLines.join(', \n')})${cascadeLines.join('\n')};
      ${postLines.join('\n')}
      return object;
    }''';
  }

  static String toOneRelations(ModelEntity entity) =>
      // ignore: prefer_interpolation_to_compose_strings
      '[' +
      entity.properties
          .where((ModelProperty prop) => prop.isRelation)
          .map((ModelProperty prop) => 'object.${propertyFieldName(prop)}')
          .join(',') +
      ']';

  static String relInfo(ModelEntity entity, ModelRelation rel) =>
      '$obxInt.RelInfo<${entity.name}>.toMany(${rel.id.id}, object.${propertyFieldAccess(entity.idProperty, '!')})';

  static String backlinkRelInfo(ModelEntity entity, ModelBacklink bl) {
    final source = bl.source;
    if (source is BacklinkSourceRelation) {
      return '$obxInt.RelInfo<${bl.srcEntity}>.toManyBacklink('
          '${source.srcRel.id.id}, object.${propertyFieldAccess(entity.idProperty, '!')})';
    } else if (source is BacklinkSourceProperty) {
      return '$obxInt.RelInfo<${bl.srcEntity}>.toOneBacklink('
          '${source.srcProp.id.id}, object.${propertyFieldAccess(entity.idProperty, '!')}, '
          '(${bl.srcEntity} srcObject) => srcObject.${propertyFieldName(source.srcProp)})';
    } else {
      throw InvalidGenerationSourceError('Unknown relation backlink source for ${entity.name}.${bl.name}');
    }
  }

  static String toManyRelations(ModelEntity entity) {
    final definitions = <String>[];
    definitions.addAll(entity.relations.map((ModelRelation rel) => '${relInfo(entity, rel)}: object.${rel.name}'));
    definitions.addAll(entity.backlinks.map((ModelBacklink bl) => '${backlinkRelInfo(entity, bl)}: object.${bl.name}'));
    return '{${definitions.join(',')}}';
  }

  static String _metaClass(int i, ModelEntity entity) {
    final fields = <String>[];
    for (var p = 0; p < entity.properties.length; p++) {
      final prop = entity.properties[p];
      final name = prop.name;

      // see OBXPropertyType
      String fieldType;
      switch (prop.type) {
        case OBXPropertyType.Bool:
          fieldType = 'Boolean';
          break;
        case OBXPropertyType.String:
          fieldType = 'String';
          break;
        case OBXPropertyType.Float:
        case OBXPropertyType.Double:
          fieldType = 'Double';
          break;
        case OBXPropertyType.Byte:
        case OBXPropertyType.Short:
        case OBXPropertyType.Char:
        case OBXPropertyType.Int:
        case OBXPropertyType.Long:
          fieldType = 'Integer';
          break;
        case OBXPropertyType.Date:
          fieldType = 'Date';
          break;
        case OBXPropertyType.DateNano:
          fieldType = 'DateNano';
          break;
        case OBXPropertyType.Relation:
          fieldType = 'Relation';
          break;
        case OBXPropertyType.ByteVector:
          fieldType = 'ByteVector';
          break;
        case OBXPropertyType.CharVector:
        case OBXPropertyType.ShortVector:
        case OBXPropertyType.IntVector:
        case OBXPropertyType.LongVector:
          fieldType = 'IntegerVector';
          break;
        case OBXPropertyType.FloatVector:
        case OBXPropertyType.DoubleVector:
          fieldType = 'DoubleVector';
          break;
        case OBXPropertyType.StringVector:
          fieldType = 'StringVector';
          break;
        default:
          throw InvalidGenerationSourceError('Unsupported property type (${prop.type}): ${entity.name}.$name');
      }

      var propCode = '''
        /// see [${entity.name}.${propertyFieldName(prop)}]
        static final ${propertyFieldName(prop)} = ''';
      if (prop.isRelation) {
        propCode += '$obx.QueryRelationToOne<${entity.name}, ${prop.relationTarget}>';
      } else {
        propCode += '$obx.Query${fieldType}Property<${entity.name}>';
      }
      propCode += '(entities[$i].properties[$p]);';
      fields.add(propCode);
    }

    for (var r = 0; r < entity.relations.length; r++) {
      final rel = entity.relations[r];
      final targetEntityName = entity.model.findEntityByUid(rel.targetId.uid)!.name;
      fields.add('''
          /// see [${entity.name}.${rel.name}]
          static final ${rel.name} = $obx.QueryRelationToMany'''
          '<${entity.name}, $targetEntityName>(entities[$i].relations[$r]);');
    }

    // Add fields for to-many based on to-one backlinks
    for (var backlink in entity.backlinks) {
      final source = backlink.source;
      // Query conditions only supported for backlinks from a to-one,
      // also there is currently no common super type of QueryRelationToOne
      // and QueryRelationToMany.
      if (source is BacklinkSourceProperty) {
        // /// see [Entity.backlinkName]
        // static final backlinkName = QueryBacklinkToMany<Source, Entity>(Source_.srcField);
        fields.add('''
          /// see [${entity.name}.${backlink.name}]
          static final ${backlink.name} = $obx.QueryBacklinkToMany<${backlink.srcEntity}, ${entity.name}>(${backlink.srcEntity}_.${propertyFieldName(source.srcProp)});
        ''');
      }
    }

    return '''
      /// [${entity.name}] entity fields to define ObjectBox queries.
      class ${entity.name}_ {${fields.join()}}
    ''';
  }
}

extension _Pubspec on Pubspec {
  static final infixes = ['', '_sync'];

  static String depPackage(String infix) => 'objectbox${infix}_flutter_libs';

  String get obxFlutterImport {
    for (var i = 0; i < infixes.length; i++) {
      final dep = depPackage(infixes[i]);
      if (dependencies[dep] != null) {
        return "\nimport 'package:$dep/$dep.dart';";
      }
    }
    return '';
  }

  bool get hasObxFlutterDependency => infixes.any((infix) => dependencies[depPackage(infix)] != null);
}
