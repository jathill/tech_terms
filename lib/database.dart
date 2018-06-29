import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:tech_terms/Term.dart';

class TermDatabase {
  static final TermDatabase _termDatabase = new TermDatabase._internal();

  final String tableName0 = "Terms";
  final String tableName1 = "Tags";
  final String tableName2 = "Related";

  Database db;

  bool didInit = false;

  static TermDatabase get() {
    return _termDatabase;
  }

  TermDatabase._internal();

  /// Use this method to access the database, because initialization of the database (it has to go through the method channel)
  Future<Database> _getDb() async {
    if (!didInit) await _init();
    return db;
  }

  Future init() async {
    return await _init();
  }

  Future _init() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "techTerms.db");
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db
          .execute("CREATE TABLE $tableName0 ("
              "${Term.db_id} STRING PRIMARY KEY,"
              "${Term.db_name} TEXT,"
              "${Term.db_definition} TEXT,"
              "${Term.db_maker} TEXT,"
              "${Term.db_year} INTEGER,"
              "${Term.db_abbreviation} TEXT"
              ")")
          .then((context) => print("Term db created"));
      await db
          .execute("CREATE TABLE $tableName1 ("
              "${Tag.db_id} STRING PRIMARY KEY,"
              "${Tag.db_name} TEXT,"
              "FOREIGN KEY (${Tag.db_term_id}) REFERENCES ${tableName0} (id) ON DELETE NO ACTION ON UPDATE NO ACTION"
              ")")
          .then((context) => print("Tag db created"));
      await db
          .execute("CREATE TABLE $tableName2 ("
          "${Relation.db_id} STRING PRIMARY KEY,"
          "${Relation.db_to_term} TEXT,"
          "FOREIGN KEY (${Relation.db_from_term}) REFERENCES ${tableName0} (id) ON DELETE NO ACTION ON UPDATE NO ACTION"
          ")")
          .then((context) => print("Tag db created"));
    }).then((createdDB) {
      print("db opened");
      return createdDB;
    });

    await addTermsFromFile().then((termList) {
      termList.forEach((t) => updateTerm(t));
    });

//    final versionPath = await getApplicationDocumentsDirectory().then((dir) {
//      return dir.path;
//    });
//    final versionFile = File('$versionPath/version.txt');
//
//    int serverVersion = await getServerVersion();
//    int localVersion = await getLocalVersion(versionFile);
//    print("Server version $serverVersion; Local version $localVersion");
//
//    if (serverVersion == -1)
//      print("Error: Could not contact server");
//    else if (serverVersion != localVersion) {
//      await addTermsFromServer().then((termList) {
//        termList.forEach((t) => updateTerm(t));
//      });
//      versionFile.writeAsString("$serverVersion");
//    }

    didInit = true;
  }

  Future<int> getServerVersion() async {
    final url = 'https://tech-terms.herokuapp.com/get_version';
    return await http.get(url).then((response) {
      if (response.statusCode != 200) return -1;
      return json.decode(response.body)["version"];
    });
  }

  Future<int> getLocalVersion(File file) async {
    try {
      String contents = await file.readAsString();
      return int.parse(contents);
    } catch (FileSystemException) {
      return 0;
    }
  }

  /// Get a book by its id, if there is not entry for that ID, returns null.
  Future<Term> getTerm(String id) async {
    var db = await _getDb();
    var result = await db
        .rawQuery('SELECT * FROM $tableName0 WHERE ${Term.db_id} = "$id"');
    if (result.length == 0) return null;
    return new Term.fromMap(result[0]);
  }

  /// Get all terms from local database, return a list with all the terms
  Future<List<Term>> getAllTerms() async {
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM $tableName0');
    List<Term> dbTerms = [];
    print(result[0]);
    for (Map<String, dynamic> item in result) {
      dbTerms.add(new Term.fromMap(item));
    }
    return dbTerms;
  }

  /// Get most recent terms from server and return them in a list
  Future<List<Term>> addTermsFromServer() async {
    final url = 'https://tech-terms.herokuapp.com/get_terms';

    var terms = await http.get(url).then((response) {
      print("received terms response");
      List<Term> termList = [];
      json.decode(response.body).forEach((termJson) {
        termList.add(Term.fromJson(termJson));
      });
      return termList;
    });
    return terms;
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
        tags: ["Application Frameworks"],
        related: ["C#"]);
    Term term3 = new Term(
        name: "SQL", definition: "see Structured Query Language", id: "3");
    Term term4 = new Term(
        name: "Git",
        definition:
            "Version control system for tracking changes in files. Primarily used for source code management.",
        id: "4",
        maker: "Linus Torvalds",
        year: 2005);

    return [term1, term2, term3, term4];
  }

  //TODO escape not allowed characters eg. ' " '
  /// Inserts or replaces the book.
  Future updateTerm(Term term) async {
    await db.rawInsert(
        'INSERT OR REPLACE INTO '
        '$tableName0(${Term.db_id}, ${Term.db_name}, ${Term.db_definition}, ${Term.db_maker}, ${Term.db_year}, ${Term.db_tags}, ${Term.db_related}, ${Term.db_abbreviation})'
        ' VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [
          term.id,
          term.name,
          term.definition,
          term.maker,
          term.year,
          term.tags,
          term.related,
          term.abbreviation
        ]);
  }

  Future close() async {
    var db = await _getDb();
    return db.close();
  }
}
