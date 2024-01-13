import 'data_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PersonRepository {
  Future<Person> getPerson(String id) async {
    Person? person = await _getPersonFromCache(id);
    if (person == null) {
      person = await _fetchPerson(id);
      await _cachePerson(person);
    }
    return person;
  }

  Future<Person?> _getPersonFromCache(String id) async {
    final cacheFile = await _getPersonFile(id);

    if (await cacheFile.exists()) {
      final jsonString = await cacheFile.readAsString();
      return Person.fromJson(json.decode(jsonString));
    }

    return null;
  }

  Future<void> _cachePerson(Person person) async {
    final cacheFile = await _getPersonFile(person.personID);

    await cacheFile.writeAsString(json.encode(person.toJson()));
  }

  Future<Person> _fetchPerson(String id) async {
    final response = await http.get(
      Uri.parse(
          'https://storage.googleapis.com/flame-finder-profiles/profiles_v2/${id}.dat'),
      headers: {
        HttpHeaders.acceptEncodingHeader: 'gzip', // Request gzip encoding
      },
    );

    if (response.statusCode == 200) {
      String decodedBody;
      if (response.headers[HttpHeaders.contentEncodingHeader] == 'gzip') {
        decodedBody = utf8.decode(GZipCodec().decode(response.bodyBytes));
      } else {
        decodedBody = utf8.decode(response.bodyBytes);
      }

      Map<String, dynamic> jsonResponse = json.decode(decodedBody);
      var profile = Person.fromJson(jsonResponse);
      return profile;
    } else {
      throw Exception('Failed to load person');
    }
  }
}

Future<File> _getPersonFile(String id) async {
  final directory = await getApplicationDocumentsDirectory();
  final flameFinderDirectory = Directory('${directory.path}/flame_finder');

  // Create the flame_finder directory if it doesn't exist
  if (!await flameFinderDirectory.exists()) {
    flameFinderDirectory.createSync(recursive: true);
  }

  return File('${flameFinderDirectory.path}/person_$id.json');
}
