import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tech_terms/Term.dart';


class TermDatabase {
  static final TermDatabase _termDatabase = new TermDatabase._internal();

  final String tableName = "Terms";

  Database db;

  bool didInit = false;

  static TermDatabase get() {
    return _termDatabase;
  }

  TermDatabase._internal();


  /// Use this method to access the database, because initialization of the database (it has to go through the method channel)
  Future<Database> _getDb() async{
    print(didInit);
    if(!didInit) await _init();
    else {
      await addTermsFromFile().then((termList) {
        termList.forEach((t) => updateTerm(t));
      });
    }
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
          await db.execute(
              "CREATE TABLE $tableName ("
                  "${Term.db_id} STRING PRIMARY KEY,"
                  "${Term.db_name} TEXT,"
                  "${Term.db_definition} TEXT,"
                  "${Term.db_maker} TEXT,"
                  "${Term.db_year} INTEGER"
                  ")");
        });
    await addTermsFromFile().then((termList) {
      termList.forEach((t) => updateTerm(t));
    });
    didInit = true;
  }

  /// Get a book by its id, if there is not entry for that ID, returns null.
  Future<Term> getTerm(String id) async{
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM $tableName WHERE ${Term.db_id} = "$id"');
    if(result.length == 0)return null;
    return new Term.fromMap(result[0]);
  }

  /// Get all terms, will return a list with all the terms
  Future<List<Term>> getAllTerms() async{
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM $tableName');
    List<Term> dbTerms = [];
    for(Map<String, dynamic> item in result) {
      dbTerms.add(new Term.fromMap(item));
    }
    return dbTerms;
  }
  
  Future<List<Term>> addTermsFromFile() async {
    Term term1 = new Term(name: "C#",
        definition: "High level programming language within the .NET framework.",
        id: "1", maker: "Microsoft", year: 2000);
    Term term2 = new Term(name: "Ruby on Rails",
        definition: "Server-side web application framework written in Ruby.",
        id: "2", maker: "David Heinemmeier Hansson", year: 2005);
    Term term3 = new Term(name: "SQL",
        definition: "see Structured Query Language",
        id: "3");

    return [term1, term2, term3];
  }

  //TODO escape not allowed characters eg. ' " '
  /// Inserts or replaces the book.
  Future updateTerm(Term term) async {
    await db.rawInsert(
        'INSERT OR REPLACE INTO '
            '$tableName(${Term.db_id}, ${Term.db_name}, ${Term.db_definition}, ${Term.db_maker}, ${Term.db_year})'
            ' VALUES(?, ?, ?, ?, ?)',
        [term.id, term.name, term.definition, term.maker, term.year]);

  }

  Future close() async {
    var db = await _getDb();
    return db.close();
  }

}