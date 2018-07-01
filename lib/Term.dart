import 'package:meta/meta.dart';

// REF: https://proandroiddev.com/flutter-bookshelf-app-part-2-personal-notes-and-database-integration-a3b47a84c57

class Relation {
  static final db_id = "id";
  static final db_from_term = "From_term";
  static final db_to_term = "To_term";

  String id, from_term, to_term;

  Relation({
    @required this.id,
    @required this.from_term,
    @required this.to_term,
  });

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
        id: json['id'], from_term: json['from_term'], to_term: json['to_term']);
  }

  Relation.fromMap(Map<String, dynamic> map)
      : this(
            id: map[db_id],
            from_term: map[db_from_term],
            to_term: map[db_to_term]);
}

class Tag {
  static final db_name = "Name";
  static final db_id = "id";
  static final db_term_id = "Term_id";

  String name, id, term_id;

  Tag({
    @required this.name,
    @required this.id,
    @required this.term_id,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(name: json['name'], id: json['id'], term_id: json['term_id']);
  }

  Tag.fromMap(Map<String, dynamic> map)
      : this(name: map[db_name], id: map[db_id], term_id: map[db_term_id]);
}

class Term {
  static final db_name = "Name";
  static final db_definition = "Definition";
  static final db_id = "id";
  static final db_maker = "Creator";
  static final db_year = "Year_Created";
  static final db_abbreviation = "Abbreviation";
  static final db_tags = "Tags";
  static final db_related = "Related";

  String name, id, definition, maker, abbreviation;
  int year;
  List<String> tags, related;

  Term(
      {@required this.name,
      @required this.definition,
      @required this.id,
      this.maker,
      this.year,
      this.tags,
      this.related,
      this.abbreviation});

  factory Term.fromJson(Map<String, dynamic> json) {
    var term = Term(
        name: json['name'], definition: json['definition'], id: json['id']);
    if (json.containsKey("maker")) term.maker = json['maker'];
    if (json.containsKey("year")) term.year = json['year'];
    if (json.containsKey("tags")) term.tags = json['tags'];
    if (json.containsKey("related")) term.related = json['related'];
    if (json.containsKey("abbreviation")) term.abbreviation = json['abbr'];
    return term;
  }

  Term.fromMap(Map<String, dynamic> map)
      : this(
          name: map[db_name],
          definition: map[db_definition],
          id: map[db_id].toString(),
          maker: map[db_maker],
          year: map[db_year],
        );
}
