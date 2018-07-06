import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tech_terms/Term.dart';
import 'package:http/http.dart' as http;

class TermDatabase {
  static final TermDatabase _termDatabase = new TermDatabase._internal();

  final String termTableName = "Terms";
  final String tagTableName = "Tags";
  final String relationTableName = "Related";

  Database db;
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

//    await addTermsFromFile().then((termList) {
//      termList.forEach((t) => updateTerm(t));
//    });

    final File versionFile = File("${documentsDirectory.path}/version.txt");
    final int serverVersion = await getServerVersion();
    final int localVersion = await getLocalVersion(versionFile);
    print("Server version $serverVersion; Local version $localVersion");

    // Checks if local database version is up-to-date, and downloads updated
    // terms if necessary
    if (serverVersion == -1)
      print("Error: Could not contact server");
    else if (serverVersion != localVersion) {
      await updateDatabase();
      versionFile.writeAsString("$serverVersion");
    }

    didInit = true;
    setTags(await getAllTerms()).then((context) => setRelated(_cachedTerms));
  }

  /// Creates tables for [db] and returns it
  Future<Database> createDatabase(Database db) async {
    await db.execute("CREATE TABLE $termTableName ("
        "${Term.db_id} STRING PRIMARY KEY,"
        "${Term.db_name} TEXT NOT NULL,"
        "${Term.db_definition} TEXT NOT NULL,"
        "${Term.db_maker} TEXT,"
        "${Term.db_year} INTEGER,"
        "${Term.db_abbreviation} TEXT"
        ")");
    await db.execute("CREATE TABLE $tagTableName ("
        "${Tag.db_id} STRING PRIMARY KEY,"
        "${Tag.db_name} TEXT NOT NULL,"
        "${Tag.db_term_id} TEXT NOT NULL,"
        "FOREIGN KEY (${Tag.db_term_id}) REFERENCES ${termTableName} (id)"
        ")");
    await db.execute("CREATE TABLE $relationTableName ("
        "${Relation.db_id} STRING PRIMARY KEY,"
        "${Relation.db_to_term} TEXT NOT NULL,"
        "${Relation.db_from_term} TEXT NOT NULL,"
        "FOREIGN KEY (${Relation.db_from_term}) REFERENCES ${termTableName} (id)"
        ")");

    return db;
  }

  /// Get updated terms from server and add to local database
  Future<void> updateDatabase() async {
    await addTermsFromServer().then((serverDict) {
      final termList = serverDict['terms'];
      final tagList = serverDict['tags'];
      final relationList = serverDict['related'];

      termList.forEach((t) => updateTerm(t));
      tagList.forEach((t) => updateTag(t));
      relationList.forEach((r) => updateRelation(r));
    });
  }

  /// Returns server database version
  Future<int> getServerVersion() async {
    final url = 'https://tech-terms.herokuapp.com/get_version';
    return await http.get(url).then((response) {
      if (response.statusCode != 200) return -1;
      return json.decode(response.body)["version"];
    });
  }

  /// If [file] not found, returns 0, else returns local DB version from [file]
  Future<int> getLocalVersion(File file) async {
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

    _cachedTerms = dbTerms;
    return dbTerms;
  }

  /// Gets tag name list from server, returns map of names to list of terms
  /// with that tag
  Future<Map<String, List<Term>>> getTags() async {
    final url = 'https://tech-terms.herokuapp.com/get_tag_names';
    return await http.get(url).then((response) async {
      //if (response.statusCode != 200) getFromDB();
      List<String> tagNames = List<String>.from(json.decode(response.body));

      Map<String, List<Term>> tagMap = {};
      await Future.forEach(tagNames, (String name) async {
        tagMap[name] = await getTermsForTag(name);
      });

      return tagMap;
    });
  }

  /// Returns list of terms with tag [tagName]
  Future<List<Term>> getTermsForTag(String tagName) async {
    var db = await _getDb();
    var result =
        await db.rawQuery("SELECT ${Tag.db_term_id} FROM $tagTableName "
            "WHERE ${Tag.db_name} = '$tagName'");

    List<String> termIDs = [];
    result.forEach((item) {
      termIDs.add(item[Tag.db_term_id]);
    });

    List<Term> termList = [];
    termIDs.forEach((id) {
      termList.add(_cachedTerms.firstWhere((t) => t.id == id));
    });

    termList.sort();
    return termList;
  }

  /// Gets terms, tags, and relations from server, returns them in a map
  Future<Map<String, dynamic>> addTermsFromServer() async {
    final termURL = 'https://tech-terms.herokuapp.com/get_terms';
    final tagsURL = 'https://tech-terms.herokuapp.com/get_tags';
    final relatedURL = 'https://tech-terms.herokuapp.com/get_related';

    var terms = await http.get(termURL).then((response) {
      List<Term> termList = [];
      json.decode(response.body).forEach((termJson) {
        termList.add(Term.fromJson(termJson));
      });
      return termList;
    });

    var tags = await http.get(tagsURL).then((response) {
      List<Tag> tagList = [];
      json.decode(response.body).forEach((tagJson) {
        tagList.add(Tag.fromJson(tagJson));
      });
      return tagList;
    });

    var related = await http.get(relatedURL).then((response) {
      List<Relation> relationList = [];
      json.decode(response.body).forEach((relationJson) {
        relationList.add(Relation.fromJson(relationJson));
      });
      return relationList;
    });

    return {"terms": terms, "tags": tags, "related": related};
  }

  /// Get most recent terms from file and return them in a list
  Future<List<Term>> addTermsFromFile() async {
    Term term1 = new Term(
        name: "C#",
        definition:
            "High level programming language within the .NET framework.",
        id: "1",
        maker: "Microsoft",
        year: 2000,
        tags: ["Programming Languages"]);
    Term term2 = new Term(
        name: "Ruby on Rails",
        definition: "Server-side web application framework written in Ruby.",
        id: "2",
        maker: "David Heinemmeier Hansson",
        year: 2005,
        tags: ["Application Frameworks"]);
    Term term3 = new Term(
        name: "SQL",
        definition: "see Structured Query Language",
        id: "3",
        abbreviation: "Structured Query Language");
    Term term4 = new Term(
        name: "Git",
        definition:
            "Version control system for tracking changes in files. Primarily used for source code management.",
        id: "4",
        maker: "Linus Torvalds",
        year: 2005);

    return [term1, term2, term3, term4];
  }

  /// Inserts or replaces [term] in local database
  Future updateTerm(Term term) async {
    await db.rawInsert(
        'INSERT OR REPLACE INTO '
        '$termTableName(${Term.db_id}, ${Term.db_name}, ${Term.db_definition}, ${Term.db_maker}, ${Term.db_year}, ${Term.db_abbreviation})'
        ' VALUES(?, ?, ?, ?, ?, ?)',
        [
          term.id,
          term.name,
          term.definition,
          term.maker,
          term.year,
          term.abbreviation
        ]);
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
