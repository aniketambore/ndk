import 'dart:convert';

import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

import '../nip01/event.dart';

class Nip02ContactList {
  static const int kind = 3;
  late String pubKey;

  List<String> contacts = [];
  List<String> contactRelays = [];
  List<String> petnames = [];

  List<String> followedTags = [];
  List<String> followedCommunities = [];
  List<String> followedEvents = [];

  Map<String, ReadWriteMarker> relaysInContent = {};

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  int? loadedTimestamp;

  List<String> sources = [];

  Nip02ContactList(this.pubKey, this.contacts);

  Nip02ContactList.fromEvent(Nip01Event event) {
    pubKey = event.pubKey;
    createdAt = event.createdAt;
    loadedTimestamp = DateTime.now().millisecondsSinceEpoch ~/1000;
    for (var tag in event.tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final name = tag[0];
      final contact = tag[1];
      if (name == "p") {
        String relay = '';
        String petname = '';
        if (length > 2) {
          relay = tag[2];
          if (length > 3) {
            petname = tag[3];
          }
        }
        contacts.add(contact);
        contactRelays.add(relay);
        petnames.add(petname);
      } else if (name == "t" && length > 1) {
        var tagName = tag[1];
        followedTags.add(tagName);
      } else if (name == "a" && length > 1) {
        var id = tag[1];
        followedCommunities.add(id);
      } else if (name == "e" && length > 1) {
        var id = tag[1];
        followedEvents.add(id);
      }
    }
    if (Helpers.isNotBlank(event.content)) {
      try {
        Map<String, dynamic> json = jsonDecode(event.content);
        if (json.entries.isNotEmpty) {
          for (var entry in json.entries) {
            try {
              bool read = entry.value["read"] ?? false;
              bool write = entry.value["write"] ?? false;
              if (read || write) {
                relaysInContent[entry.key] =
                    ReadWriteMarker.from(read: read, write: write);
              }
            } catch (e) {
              try {
                Map<String, dynamic> decodedValue = jsonDecode(entry.value);
                bool read = decodedValue["read"] ?? false;
                bool write = decodedValue["write"] ?? false;
                if (read || write) {
                  relaysInContent[entry.key] =
                      ReadWriteMarker.from(read: read, write: write);
                }
                continue;
              } catch (e) {
                print(
                    "Could not parse relay ${entry.key} , entry : ${entry.value}");
              }
              print(
                  "Could not parse relay ${entry.key} , content : ${event.content}");
            }
          }
        }
      } catch (e) {
        // invalid json in content, ignore
      }
    }
    sources.addAll(event.sources);
  }

  List<List<String>> contactsToJson() {
    return contacts.map((contact) {
      int idx = contacts.indexOf(contact);
      List<String> list = [
        "p",
        contact,
        contactRelays.length > idx ? contactRelays[idx] : "",
        petnames.length > idx ? petnames[idx] : ""
      ];
      return list;
    }).toList();
  }

  List<List<String>> tagListToJson(final List<String> list, String tag) {
    return list.map((value) {
      List<String> list = [
        tag,
        value,
      ];
      return list;
    }).toList();
  }

  Nip01Event toEvent() {
    return Nip01Event(
      pubKey: pubKey,
      kind: Nip02ContactList.kind,
      tags: contactsToJson()..addAll(tagListToJson(followedTags, "t"))..addAll(tagListToJson(followedCommunities, "a"))..addAll(tagListToJson(followedEvents, "e")),
      content: "",
      publishAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Nip02ContactList && runtimeType == other.runtimeType && pubKey == other.pubKey;

  @override
  int get hashCode => pubKey.hashCode;
}
