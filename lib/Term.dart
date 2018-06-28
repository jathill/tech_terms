import 'package:meta/meta.dart';

// REF: https://proandroiddev.com/flutter-bookshelf-app-part-2-personal-notes-and-database-integration-a3b47a84c57

class Tag {
  static final abbreviations = "Abbreviations";
  static final applicationFrameworks = "Application Frameworks";
  static final cloudHosting = "Cloud Hosting";
  static final concepts = "Concepts";
  static final databases = "Databases";
  static final gameEngines = "Game Engines";
  static final languageProperty = "Language Property";
  static final markupLanguage = "Markup Language";
  static final mobile = "Mobile";
  static final operatingSystem = "Operating System";
  static final programmingLanguages = "Programming Languages";
  static final queryLanguages = "Query Languages";
  static final rdbms = "RDBMS";
  static final styleSheets = "Style Sheets";
  static final tools = "Tools";
  static final versionControl = "Version Control";
  static final web = "Web";
}

class Term {
  static final db_name = "Name";
  static final db_definition = "Definition";
  static final db_id = "id";
  static final db_maker = "Creator";
  static final db_year = "Year_Created";
  static final db_tags = "Tags";
  static final db_related = "Related";
  static final db_abbreviation = "Abbreviation";

  String name, id, definition, maker, abbreviation;
  int year;
  List<String> tags, related;

  Term({
    @required this.name,
    @required this.definition,
    @required this.id,
    this.maker,
    this.year,
    this.tags,
    this.related,
    this.abbreviation
  });

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
          //tags: map[db_tags],
          //related: map[db_related],
        );

}
