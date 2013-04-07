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

class EbnfParser < Parslet::Parser
  root(:grammar)

  def padded(with=space)
    with.repeat(0) >> yield >> with.repeat(0)
  end

  def any_up_until(atom)
    (atom.absent? >> any).repeat
  end

  rule(:grammar)         { production.as(:production) >> (new_line.repeat >> production.as(:production)).repeat(0) }
  rule(:production)      { padded(whitespace) { name.as(:name) >> padded { str('::=') } >> ( choice | link ).as(:definition) } }
  rule(:name)            { match['A-Z'] >> match['a-zA-Z'].repeat }
  rule(:choice)          { seq_or_diff >> ( padded { str('|') } >> seq_or_diff ).repeat }
  rule(:seq_or_diff)     { ( item >> ( (padded { str('-') } >> item) | ( space.repeat(1) >> item ).repeat ).maybe ) }
  rule(:item)            { primary.as(:primary) >> match['+*?'].maybe }
  rule(:primary)         { name.as(:name) | string_literal | char_code | char_class | ( str('(') >> padded { choice } >> str(')') ) }
  rule(:string_literal)  {
    ( str('"') >> (match['^"'].repeat(0)).as(:string) >> str('"') ) |
    ( str("'") >> (match["^'"].repeat(0)).as(:string) >> str("'") )}
  rule(:char_code)       { str('#x') >> match['0-9a-fA-F'].repeat(1) }
  rule(:char_class)      { str('[') >> str('^').maybe >> ( str(']').absent? >> char | char_code | char_range | char_code_range ).repeat(1) >> str(']') }
  rule(:char)            { match('[[:print:]]') }
  rule(:char_range)      { char >> str('-') >> char }
  rule(:char_code_range) { char_code >> str('-') >> char_code }
  rule(:link)            { str('[') >> url >> str(']') }
  rule(:url)             { match['^\x5D:/?#'].repeat(1) >> str('://') >> match['^\x5D#'].repeat(1) >> ( str('#') >> name ).maybe }
  rule(:whitespace)      { space | new_line | comment }
  rule(:new_line)        { match['\r\n'] }
  rule(:space)           { match['\t '] }
  rule(:comment)         { str('/*') >> any_up_until(str('*/')) >> str('*/') }
end
