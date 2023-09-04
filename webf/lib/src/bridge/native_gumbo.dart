import 'dart:ffi';

import 'package:ffi/ffi.dart';

class NativeGumboOutput extends Struct {
  external Pointer<NativeGumboNode> document;
  external Pointer<NativeGumboNode> root;
  external NativeGumboVector errors;
}

class NativeGumboStringPiece extends Struct {
  external Pointer<Utf8> data;

  @Size()
  external int length;
}

class NativeGumboVector extends Struct {
  external Pointer<Pointer<Void>> data;

  @Uint32()
  external int length;

  @Uint32()
  external int capacity;
}

class NativeGumboSourcePosition extends Struct {
  @Uint32()
  external int line;
  @Uint32()
  external int column;
  @Uint32()
  external int offset;
}

class NativeGumboNode extends Struct {
  @Int32()
  external int type;

  external Pointer<NativeGumboNode> parent;

  @Size()
  external int index_within_parent;

  @Int32()
  external int parse_flags;

  external NativeGumboNodeUnionValue v;
}

class NativeGumboNodeUnionValue extends Union {
  external NativeGumboDocument document;

  external NativeGumboElement element;

  external NativeGumboText text;
}

class NativeGumboDocument extends Struct {
  external NativeGumboVector children;

  @Bool()
  external bool has_doctype;

  external Pointer<Uint8> name;

  external Pointer<Uint8> public_identifier;

  external Pointer<Uint8> system_identifier;

  @Int32()
  external int doc_type_quirks_mode;
}

class NativeGumboElement extends Struct {
  external NativeGumboVector children;
  @Int32()
  external int tag;

  @Int32()
  external int tag_namespace;

  external NativeGumboStringPiece original_tag;

  external NativeGumboStringPiece original_end_tag;

  external NativeGumboSourcePosition start_pos;

  external NativeGumboSourcePosition end_pos;

  external NativeGumboVector attributes;
}

class NativeGumboText extends Struct {
  external Pointer<Uint8> text;

  external NativeGumboStringPiece original_text;

  external NativeGumboSourcePosition start_pos;
}

class NativeGumboAttribute extends Struct {
  @Int32()
  external int attr_namespace;

  external Pointer<Utf8> name;

  external NativeGumboStringPiece original_name;

  external Pointer<Utf8> value;

  external NativeGumboStringPiece original_value;

  external NativeGumboSourcePosition name_start;
  external NativeGumboSourcePosition name_end;

  external NativeGumboSourcePosition value_start;
  external NativeGumboSourcePosition value_end;
}
