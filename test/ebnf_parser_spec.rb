require 'minitest/spec'
require 'minitest/autorun'

require_relative "support/parser_matchers"

require_relative "../lib/syntrax/ebnf_parser"

describe EbnfParser do
  let(:parser)  { EbnfParser.new }
  let(:grammar) do
    %Q{
      /* A self-describing example grammar of the W3C-style EBNF syntax */

      Grammar              ::= Production*
      Production           ::= NCName '::=' ( Choice | Link )
      NCName               ::= [http://www.w3.org/TR/xml-names/#NT-NCName]
      Choice               ::= SequenceOrDifference ( '|' SequenceOrDifference )*
      SequenceOrDifference ::= (Item ( '-' Item | Item* ))?
      Item                 ::= Primary ( '?' | '*' | '+' )?
      Primary              ::= NCName | StringLiteral | CharCode | CharClass | '(' Choice ')'
      StringLiteral        ::= '"' [^"]* '"' | "'" [^']* "'"
      CharCode             ::= '#x' [0-9a-fA-F]+
      CharClass            ::= '[' '^'? ( Char | CharCode | CharRange | CharCodeRange )+ ']'
      Char                 ::= [http://www.w3.org/TR/xml#NT-Char]
      CharRange            ::= Char '-' ( Char - ']' )
      CharCodeRange        ::= CharCode '-' CharCode
      Link                 ::= '[' URL ']'
      URL                  ::= [^#x5D:/?#]+ '://' [^#x5D#]+ ('#' NCName)?
      Whitespace           ::= S | Comment
      S                    ::= #x9 | #xA | #xD | #x20
      Comment              ::= '/*' ( [^*] | '*'+ [^*/] )* '*'* '*/'
    }
  end

  it "parses a simple rule" do
    parser.must_parse "Grammar ::= Production*"
  end

  it "parses rules with choices" do
    parser.must_parse \
      "Whitespace ::= S | Comment\n" +
      "S          ::= #x9 | #xA | #xD | #x20"
  end

  it "parses its own grammar" do
    skip
    parser.must_parse grammar
  end
end