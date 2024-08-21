import "package:realm/realm.dart";

part "schemas.g.dart";

@RealmModel()
class _Version {
  @PrimaryKey()
  late String module;
  late String version;
}

@RealmModel()
class _Destination {
  @PrimaryKey()
  late int id;
  late String name;
  late int version;
}