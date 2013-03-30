require 'parslet'

=begin
A self-describing example grammar of the W3C-style EBNF syntax;

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

  def padded
    space.repeat(0) >> yield >> space.repeat(0)
  end

  def any_up_until(atom)
    ((any >> atom.absent?).repeat >> any).maybe
  end

  rule(:grammar)         { whitespace.repeat(0) >> production.as(:production) >> (new_line.repeat >> production.as(:production)).repeat(0) }
  rule(:production)      { padded { name.as(:rule) >> padded { str('::=') } >> ( choice.as(:or) | link ).as(:definition) } }
  rule(:name)            { match['A-Z'] >> match['a-zA-Z'].repeat }
  rule(:choice)          { seq_or_diff.as(:option) >> ( padded { str('|') } >> seq_or_diff.as(:option) ).repeat }
  rule(:seq_or_diff)     { ( item >> ( (padded { str('-') } >> item) | ( space.repeat(1) >> item ).repeat ).maybe ) }
  rule(:item)            { primary >> match['+*?'].maybe }
  rule(:primary)         { name | string_literal | char_code | char_class | ( str('(') >> padded { choice } >> str(')') ) }
  rule(:string_literal)  { ( str('"') >> match['^"'].repeat(0) >> str('"') ) | ( str("'") >> match["^'"].repeat(0) >> str("'") )}
  rule(:char_code)       { str('#x') >> match['0-9a-fA-F'].repeat(1) }
  rule(:char_class)      { str('[') >> str('^').maybe >> ( char | char_code | char_range | char_code_range ).repeat(1) >> str(']') }
  rule(:char)            { match('[[:print:]]') }
  rule(:char_range)      { char >> str('-') >> char } # TODO: "excluding ']' from second char"
  rule(:char_code_range) { char_code >> str('-') >> char_code }
  rule(:link)            { str('[') >> url >> str(']') }
  rule(:url)             { match['^\x5D:/?#'].repeat(1) >> str('://') >> match['^\x5D#'].repeat(1) >> ( str('#') >> name ).maybe }
  rule(:whitespace)      { space | new_line | comment }
  rule(:new_line)        { match['\r\n'] }
  rule(:space)           { match['\t '] }
  rule(:comment)         { str('/*') >> any_up_until(str('*/')) >> str('*/') }
end