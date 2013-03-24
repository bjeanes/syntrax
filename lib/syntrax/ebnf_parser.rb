require 'parslet'

=begin
An self-describing example grammar of the W3C-style EBNF syntax;

  Grammar              ::=  Production*
  Production           ::=  NCName '::=' ( Choice | Link )
  NCName               ::=  [http://www.w3.org/TR/xml-names/#NT-NCName]
  Choice               ::=  SequenceOrDifference ( '|' SequenceOrDifference )*
  SequenceOrDifference ::=  (Item ( '-' Item | Item* ))?
  Item                 ::=  Primary ( '?' | '*' | '+' )?
  Primary              ::=  NCName | StringLiteral | CharCode | CharClass | '(' Choice ')'
  StringLiteral        ::=  '"' [^"]* '"' | "'" [^']* "'"
  CharCode             ::=  '#x' [0-9a-fA-F]+
  CharClass            ::=  '[' '^'? ( Char | CharCode | CharRange | CharCodeRange )+ ']'
  Char                 ::=  [http://www.w3.org/TR/xml#NT-Char]
  CharRange            ::=  Char '-' ( Char - ']' )
  CharCodeRange        ::=  CharCode '-' CharCode
  Link                 ::=  '[' URL ']'
  URL                  ::=  [^#x5D:/?#]+ '://' [^#x5D#]+ ('#' NCName)?
  Whitespace           ::=  S | Comment
  S                    ::=  #x9 | #xA | #xD | #x20
  Comment              ::=  '/*' ( [^*] | '*'+ [^*/] )* '*'* '*/'

(Taken from http://railroad.my28msec.com/rr/ui)
=end

# TODO: whitespace (e.g. newlines between grammar entries)
class EbnfParser < Parslet::Parser
  root(:grammar)

  rule(:grammar)         { form.repeat }
  rule(:form)            { name >> '::=' >> ( choice | link ) }
  rule(:name)            { match['A-Z'] >> match['a-zA-Z'].repeat }
  rule(:choice)          { seq_or_diff >> ( str('|') >> seq_or_diff ).repeat }
  rule(:seq_or_diff)     { ( item >> ( str('-') >> item | item.repeat ).maybe ) }
  rule(:item)            { primary >> match['+*?'].maybe }
  rule(:primary)         { name | string_literal | char_code | char_class | ( str('(') >> choice >> str(')') ) }
  rule(:string_literal)  { ( str('"') >> match['^"'].repeat(1) >> str('"') ) | ( str("'") >> match["^'"].repeat(1) >> str("'") )}
  rule(:char_code)       { str('#x') >> match['0-9a-fA-F'].repeat(1) }
  rule(:char_class)      { str('[') >> str('^').maybe >> ( char | char_code | char_range | char_code_range ).repeat(1) >> str(']') }
  rule(:char)            { match['\x9\xA\xD'] | match['\x20-\xD7FF'] | match['\xE000-\xFFFD'] | match['\x10000-\x10FFFF'] }
  rule(:char_range)      { char >> str('-') >> char } # TODO: "excluding ']' from second char"
  rule(:char_code_range) { char_code '-' CharCode }
  rule(:link)            { str('[') >> url >> str(']') }
  rule(:url)             { match['^\x5D:/?#'] >> str('://') >> match['^\x5D#'].repeat(1) >> ( str('#') >> name ).maybe }
  rule(:whitespace)      { space | comment }
  rule(:space)           { match['\x9\xA\xD\x20'] }
  rule(:comment)         { str('/*') >> ( match['^*'] | ( str('*') >> match['^*/'] ) ).repeat >> '*'.repeat >> '*/' }
end