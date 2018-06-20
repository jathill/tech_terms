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
    if(!didInit) await _init();
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
    List<Term> books = [];
    for(Map<String, dynamic> item in result) {
      books.add(new Term.fromMap(item));
    }
    return books;
  }

  //TODO escape not allowed characters eg. ' " '
  /// Inserts or replaces the book.
  Future updateBook(Term term) async {
    var db = await _getDb();
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