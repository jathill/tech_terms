import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:tech_terms/Term.dart';

typedef Future FutureFunction();

class TermDatabase {
  static final TermDatabase _termDatabase = new TermDatabase._internal();

  final String termTableName = "Terms";
  final String tagTableName = "Tags";
  final String relationTableName = "Related";
  final int timeoutSecs = 13;

  Database db;
  int notificationCode;
  List<Term> _cachedTerms;
  bool didInit = false;

  static TermDatabase get() {
    return _termDatabase;
  }

  TermDatabase._internal();

  Future<Database> _getDb() async {
    if (!didInit) await _init();
    return db;
  }

  Future init() async {
    return await _init();
  }

  Future _init() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "techTerms.db");

    db = await openDatabase(path,
        version: 1, onCreate: (Database db, int version) => createDatabase(db));

    await checkVersion();

    didInit = true;
    setTags(await getAllTerms()).then((context) => setRelated(_cachedTerms));
  }

  Future checkVersion() async {
    int serverVersion = await getServerVersion();
    final int localVersion = await getLocalVersion();
    print("Server version $serverVersion; Local version $localVersion");

    // Checks if local database version is up-to-date, and downloads updated
    // terms if necessary
    if (serverVersion == -1) {
      if (localVersion == 0) {
        await updateDatabase(addTermsFromFile);
        notificationCode = 0;
      } else
        notificationCode = 1;
    } else if (serverVersion != localVersion) {
      await updateDatabase(addTermsFromServer);
      getVersionFile().then((file) => file.writeAsString("$serverVersion"));
      notificationCode = 2;
    }
  }

  Future refresh() async {
    if (!didInit) await _init();

    notificationCode = null;
    await checkVersion();
    if (notificationCode == 2) {
      _cachedTerms = null;
      setTags(await getAllTerms()).then((context) => setRelated(_cachedTerms));
    }
  }

  Future<bool> isConnected() async {
    var result = await (new Connectivity().checkConnectivity());
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;
  }

  /// Creates tables for [db] and returns it
  Future<Database> createDatabase(Database db) async {
    await db.execute("CREATE TABLE $termTableName ("
        "${Term.db_id} STRING PRIMARY KEY,"
        "${Term.db_name} TEXT NOT NULL,"
        "${Term.db_definition} TEXT NOT NULL,"
        "${Term.db_maker} TEXT,"
        "${Term.db_year} INTEGER,"
        "${Term.db_starred} INTEGER NOT NULL DEFAULT 0,"
        "${Term.db_abbreviates} TEXT,"
        "${Term.db_abbreviation} TEXT"
        ")");
    await db.execute("CREATE TABLE $tagTableName ("
        "${Tag.db_id} STRING PRIMARY KEY,"
        "${Tag.db_name} TEXT NOT NULL,"
        "${Tag.db_term_id} TEXT NOT NULL,"
        "FOREIGN KEY (${Tag.db_term_id}) REFERENCES $termTableName (id)"
        ")");
    await db.execute("CREATE TABLE $relationTableName ("
        "${Relation.db_id} STRING PRIMARY KEY,"
        "${Relation.db_to_term} TEXT NOT NULL,"
        "${Relation.db_from_term} TEXT NOT NULL,"
        "FOREIGN KEY (${Relation.db_from_term}) REFERENCES $termTableName (id)"
        ")");

    return db;
  }

  /// Get updated terms from server and add to local database
  Future<void> updateDatabase(FutureFunction addTerms) async {
    await addTerms().then((serverDict) async {
      if (serverDict == null) {
        notificationCode = 1;
        return;
      }

      final termList = serverDict['terms'];
      final tagList = serverDict['tags'];
      final relationList = serverDict['related'];

      await db.rawDelete("DELETE FROM $tagTableName");
      await db.rawDelete("DELETE FROM $relationTableName");

      await Future.forEach(termList, (t) => updateTerm(t));
      tagList.forEach((t) => updateTag(t));
      relationList.forEach((r) => updateRelation(r));
    });
  }

  Future<File> getVersionFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return File("${documentsDirectory.path}/version.txt");
  }

  /// Returns server database version
  Future<int> getServerVersion() async {
    if (!await isConnected()) return -1;

    final url = 'https://tech-terms.herokuapp.com/get_version';
    try {
      return await http
          .get(url)
          .timeout(Duration(seconds: timeoutSecs))
          .then((response) {
        if (response.statusCode != 200) return -1;
        return json.decode(response.body)["version"];
      });
    } on TimeoutException {
      return -1;
    }
  }

  /// If [file] not found, returns 0, else returns local DB version from [file]
  Future<int> getLocalVersion() async {
    File file = await getVersionFile();
    try {
      String contents = await file.readAsString();
      return int.parse(contents);
    } catch (FileSystemException) {
      return 0;
    }
  }

  /// Gets tags for each term in [termList], sets its tags attribute
  Future<void> setTags(List<Term> termList) async {
    await Future.forEach(termList, (Term t) async {
      var db = await _getDb();
      var result = await db.rawQuery("SELECT ${Tag.db_name} FROM $tagTableName "
          "WHERE ${Tag.db_term_id} = '${t.id}'");

      if (result.length > 0) {
        List<String> tags = [];
        result.forEach((map) {
          tags.add(map[Tag.db_name]);
        });
        t.tags = tags;
      }
    });
  }

  /// Gets related terms for each term in [termList], sets its related attribute
  void setRelated(List<Term> termList) async {
    await Future.forEach(termList, (Term t) async {
      var db = await _getDb();
      var result = await db
          .rawQuery("SELECT ${Relation.db_to_term} FROM $relationTableName "
              "WHERE ${Relation.db_from_term} = '${t.id}'");
      if (result.length == 0)
        t.related = null;
      else {
        List<Term> related = [];
        result.forEach((map) {
          String termName = map[Relation.db_to_term];
          related.add(_cachedTerms.firstWhere((t) => t.name == termName));
        });
        t.related = related;
      }
    });
  }

  /// Returns [_cachedTerms] if not null, otherwise gets all terms from local
  /// database and returns them as a list
  Future<List<Term>> getAllTerms() async {
    if (_cachedTerms != null) return _cachedTerms;

    var db = await _getDb();
    var result = await db.rawQuery("SELECT * FROM $termTableName");

    List<Term> dbTerms = [];
    for (Map<String, dynamic> item in result) {
      dbTerms.add(new Term.fromMap(item));
    }

    dbTerms.sort();
    _cachedTerms = dbTerms;
    return dbTerms;
  }

  /// Gets tag name list from server, returns map of names to list of terms
  /// with that tag
  Future<Map<String, List<Term>>> getTagMap() async {
    final url = 'https://tech-terms.herokuapp.com/get_tag_names';
    List<String> tagNames;

    if (await getLocalVersion() == 0)
      tagNames = await getTagNamesFromDB();
    else if (!await isConnected())
      tagNames = await getTagNamesFromDB();
    else {
      try {
        await http
            .get(url)
            .timeout(Duration(seconds: timeoutSecs))
            .then((response) async {
          if (response.statusCode != 200 || await getLocalVersion() == 0)
            tagNames = await getTagNamesFromDB();
          else
            tagNames = List<String>.from(json.decode(response.body));
        });
      } on TimeoutException {
        tagNames = await getTagNamesFromDB();
      }
    }

    Map<String, List<Term>> tagMap = {};
    await Future.forEach(tagNames, (String name) async {
      tagMap[name] = await getTermsForTag(name);
    });

    return tagMap;
  }

  Future<List<String>> getTagNamesFromDB() async {
    var db = await _getDb();
    var result = await db.rawQuery("SELECT DISTINCT ${Tag.db_name} "
        "FROM $tagTableName ORDER BY ${Tag.db_name}");

    List<String> tagNames = [];
    result.forEach((item) => tagNames.add(item[Tag.db_name]));
    tagNames.sort();

    return tagNames;
  }

  /// Returns list of terms with tag [tagName]
  Future<List<Term>> getTermsForTag(String tagName) async {
    var db = await _getDb();
    var result =
        await db.rawQuery("SELECT ${Tag.db_term_id} FROM $tagTableName "
            "WHERE ${Tag.db_name} = '$tagName'");

    List<String> termIDs = [];
    result.forEach((item) => termIDs.add(item[Tag.db_term_id]));

    List<Term> termList = [];
    termIDs.forEach((id) {
      termList.add(_cachedTerms.firstWhere((t) => t.id == id));
    });

    termList.sort();
    return termList;
  }

  /// Gets terms, tags, and relations from server, returns them in a map
  Future<Map<String, dynamic>> addTermsFromServer() async {
    if (!await isConnected()) return null;

    final termURL = 'https://tech-terms.herokuapp.com/get_terms';
    final tagsURL = 'https://tech-terms.herokuapp.com/get_tags';
    final relatedURL = 'https://tech-terms.herokuapp.com/get_related';

    try {
      var terms = await http
          .get(termURL)
          .timeout(Duration(seconds: timeoutSecs))
          .then((response) {
        if (response.statusCode != 200) return null;

        List<Term> termList = [];
        json.decode(response.body).forEach((termJson) {
          termList.add(Term.fromJson(termJson));
        });
        return termList;
      });

      var tags = await http
          .get(tagsURL)
          .timeout(Duration(seconds: timeoutSecs))
          .then((response) {
        if (response.statusCode != 200) return null;

        List<Tag> tagList = [];
        json.decode(response.body).forEach((tagJson) {
          tagList.add(Tag.fromJson(tagJson));
        });
        return tagList;
      });

      var related = await http
          .get(relatedURL)
          .timeout(Duration(seconds: timeoutSecs))
          .then((response) {
        if (response.statusCode != 200) return null;

        List<Relation> relationList = [];
        json.decode(response.body).forEach((relationJson) {
          relationList.add(Relation.fromJson(relationJson));
        });
        return relationList;
      });

      return {"terms": terms, "tags": tags, "related": related};
    } on TimeoutException {
      return null;
    }
  }

  /// Get most recent terms from file and return them in a list
  Future<Map<String, dynamic>> addTermsFromFile() async {
    String contents = await rootBundle.loadString("assets/sampleData.json");
    List<Term> terms = [];
    List<Tag> tags = [];
    List<Relation> related = [];
    int tagID = 1000;
    int relatedID = 2000;

    jsonDecode(contents).forEach((termJson) {
      Term term = Term.fromJson(termJson);
      terms.add(term);

      if (termJson.containsKey("tags")) {
        termJson["tags"].forEach((tagName) {
          tags.add(Tag(name: tagName, id: tagID.toString(), termID: term.id));
        });
      }
      if (termJson.containsKey("related")) {
        termJson["related"].forEach((relation) {
          related.add(Relation(
              id: relatedID.toString(),
              fromTermID: term.id,
              toTermName: relation));
        });
      }
      tagID++;
      relatedID++;
    });

    return {"terms": terms, "tags": tags, "related": related};
  }

  /// Inserts or replaces [term] in local database
  Future updateTerm(Term term) async {
    List attrs = [
      term.id,
      term.name,
      term.definition,
      term.maker,
      term.year,
      term.abbreviates,
      term.abbreviation
    ];

    var count = await db.rawUpdate(
        'UPDATE $termTableName SET '
        '${Term.db_name} = ?,'
        '${Term.db_definition}  = ?,'
        '${Term.db_maker} = ?,'
        '${Term.db_year} = ?,'
        '${Term.db_abbreviates} = ?,'
        '${Term.db_abbreviation} = ? '
        ' WHERE ${Term.db_id} = ${term.id}',
        attrs.sublist(1));
    if (count == 0) {
      await db.rawInsert(
          'INSERT INTO '
          '$termTableName(${Term.db_id}, ${Term.db_name}, ${Term
              .db_definition}, ${Term.db_maker}, ${Term.db_year}, ${Term
              .db_abbreviates}, ${Term.db_abbreviation})'
          ' VALUES(?, ?, ?, ?, ?, ?, ?)',
          attrs);
    }
  }

  Future updateStarred(Term term) async {
    term.starred = !term.starred;
    int starred = term.starred ? 1 : 0;
    String query = 'UPDATE $termTableName SET ${Term.db_starred} = $starred '
        ' WHERE ${Term.db_id} = ${term.id}';

    try {
      await db.rawUpdate(query, [term.id, starred]);
    } catch (DatabaseException) {
      await db.rawQuery('ALTER TABLE $termTableName ADD ${Term.db_starred} '
          'INTEGER NOT NULL DEFAULT 0');
      await db.rawUpdate(query, [term.id, starred]);
    }
  }

  /// Inserts or replaces [tag] in local database
  Future updateTag(Tag tag) async {
    await db.rawInsert(
        'INSERT OR REPLACE INTO '
        '$tagTableName(${Tag.db_id}, ${Tag.db_name}, ${Tag.db_term_id})'
        ' VALUES(?, ?, ?)',
        [tag.id, tag.name, tag.termID]);
  }

  /// Inserts or replaces [relation] in local database
  Future updateRelation(Relation relation) async {
    await db.rawInsert(
        'INSERT OR REPLACE INTO '
        '$relationTableName(${Relation.db_id}, ${Relation.db_from_term}, ${Relation.db_to_term})'
        ' VALUES(?, ?, ?)',
        [relation.id, relation.fromTermID, relation.toTermName]);
  }

  Future close() async {
    var db = await _getDb();
    return db.close();
  }
}
