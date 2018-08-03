import 'package:flutter/material.dart';
import 'package:tech_terms/Term.dart';

class StarButton extends StatefulWidget {
  StarButton({@required this.term, @required this.onChanged});

  final Term term;
  final ValueChanged<Term> onChanged;

  @override
  _StarButtonState createState() => _StarButtonState();
}

class _StarButtonState extends State<StarButton> {
  bool starred;

  void _handleChanged() {
    setState(() {
      starred = !starred;
    });
    widget.onChanged(widget.term);
  }

  Widget build(BuildContext context) {
    starred = widget.term.starred;
    return IconButton(
        icon: Icon(starred ? Icons.star : Icons.star_border,
            color: starred ? Colors.yellow[600] : null),
        onPressed: _handleChanged);
  }
}