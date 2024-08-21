// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schemas.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Version extends _Version with RealmEntity, RealmObjectBase, RealmObject {
  Version(
    String module,
    String version,
  ) {
    RealmObjectBase.set(this, 'module', module);
    RealmObjectBase.set(this, 'version', version);
  }

  Version._();

  @override
  String get module => RealmObjectBase.get<String>(this, 'module') as String;
  @override
  set module(String value) => RealmObjectBase.set(this, 'module', value);

  @override
  String get version => RealmObjectBase.get<String>(this, 'version') as String;
  @override
  set version(String value) => RealmObjectBase.set(this, 'version', value);

  @override
  Stream<RealmObjectChanges<Version>> get changes =>
      RealmObjectBase.getChanges<Version>(this);

  @override
  Version freeze() => RealmObjectBase.freezeObject<Version>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Version._);
    return const SchemaObject(ObjectType.realmObject, Version, 'Version', [
      SchemaProperty('module', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('version', RealmPropertyType.string),
    ]);
  }
}

// ignore_for_file: type=lint
class Destination extends _Destination
    with RealmEntity, RealmObjectBase, RealmObject {
  Destination(
    int id,
    String name,
    int version,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'version', version);
  }

  Destination._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  int get version => RealmObjectBase.get<int>(this, 'version') as int;
  @override
  set version(int value) => RealmObjectBase.set(this, 'version', value);

  @override
  Stream<RealmObjectChanges<Destination>> get changes =>
      RealmObjectBase.getChanges<Destination>(this);

  @override
  Destination freeze() => RealmObjectBase.freezeObject<Destination>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Destination._);
    return const SchemaObject(
        ObjectType.realmObject, Destination, 'Destination', [
      SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('version', RealmPropertyType.int),
    ]);
  }
}
