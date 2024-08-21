import "package:realm/realm.dart";
import "package:couple_app/realm/schemas.dart";

class Realms {
  static Realm? realm;

  static Realm get() {
    realm ??= Realm(
      Configuration.local([
        Destination.schema,
        Version.schema,
   
      ]),
    );

    return realm!;
  }

  static void clear() {
    var realm = get();

    realm.write(() {
      realm..deleteAll<Version>();
    });
  }
}
