import 'package:meta/meta.dart';

class Relation {
  static const db_id = "id";
  static const db_from_term = "From_term";
  static const db_to_term = "To_term";

  String id, fromTermID, toTermName;

  Relation({
    @required this.id,
    @required this.fromTermID,
    @required this.toTermName,
  });

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
        id: json['id'],
        fromTermID: json['from_term'],
        toTermName: json['to_term']);
  }

  Relation.fromMap(Map<String, dynamic> map)
      : this(
            id: map[db_id],
            fromTermID: map[db_from_term],
            toTermName: map[db_to_term]);
}

class Tag {
  static const db_name = "Name";
  static const db_id = "id";
  static const db_term_id = "Term_id";

  String name, id, termID;

  Tag({
    @required this.name,
    @required this.id,
    @required this.termID,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(name: json['name'], id: json['id'], termID: json['term_id']);
  }

  Tag.fromMap(Map<String, dynamic> map)
      : this(name: map[db_name], id: map[db_id], termID: map[db_term_id]);
}

class Term extends Comparable {
  static const db_name = "Name";
  static const db_definition = "Definition";
  static const db_id = "id";
  static const db_maker = "Creator";
  static const db_year = "Year_Created";
  static const db_abbreviates = "Abbreviates";
  static const db_abbreviation = "Abbreviation";
  static const db_tags = "Tags";
  static const db_related = "Related";

  String name, id, definition, maker, abbreviates, abbreviation;
  int year;
  List<String> tags;
  List<Term> related;

  Term(
      {@required this.name,
      @required this.definition,
      @required this.id,
      this.maker,
      this.year,
      this.tags,
      this.related,
      this.abbreviates,
      this.abbreviation});

  factory Term.fromJson(Map<String, dynamic> json) {
    var term = Term(
        name: json['name'], definition: json['definition'], id: json['id']);
    if (json.containsKey("maker")) term.maker = json['maker'];
    if (json.containsKey("year")) term.year = json['year'];
    if (json.containsKey("tags")) term.tags = json['tags'];
    if (json.containsKey("related")) term.related = json['related'];
    if (json.containsKey("abbreviates")) term.abbreviates = json['abbreviates'];
    if (json.containsKey("abbreviation"))
      term.abbreviation = json['abbreviation'];
    return term;
  }

  Term.fromMap(Map<String, dynamic> map)
      : this(
          name: map[db_name],
          definition: map[db_definition],
          id: map[db_id].toString(),
          maker: map[db_maker],
          year: map[db_year],
          abbreviates: map[db_abbreviates],
          abbreviation: map[db_abbreviation],
        );

  @override
  int compareTo(other) {
    return this.name.compareTo(other.name);
  }
}
