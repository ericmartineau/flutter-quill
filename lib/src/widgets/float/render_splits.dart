import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/src/widgets/float/render_wrappable_text.dart';

class TextSplit {
  TextSplit(this.start, this.end, this.padding, this.renderer);

  final int start;
  final int end;
  final EdgeInsetsGeometry padding;
  final TextRenderer renderer;
}
