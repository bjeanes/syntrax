require 'bundler'
Bundler.setup(:default, :test)

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

  # FIXME
  describe "broken" do
    before { skip }

    specify { parser.must_parse grammar }
  end

  # Production ::= NCName '::=' ( Choice | Link )
  describe "production" do
    subject { parser.production }

    specify { subject.must_parse "Link    ::= '[' URL ']'" }
    specify { subject.must_parse "Grammar ::= Production*" }
    specify { subject.must_parse "S       ::= #x9 | #xA | #xD | #x20" }
  end

  # NCName ::= [http://www.w3.org/TR/xml-names/#NT-NCName]
  describe "name" do
    subject { parser.name }

    specify { subject.must_parse "A" }
    specify { subject.must_parse "AB" }
    specify { subject.must_parse "Ab" }
    specify { subject.must_parse "AbC" }
    specify { subject.must_not_parse "abC" }
    specify { subject.must_not_parse "A B" }
  end

  # Choice ::= SequenceOrDifference ( '|' SequenceOrDifference )*
  describe "choice" do
    subject { parser.choice }

    specify { subject.must_parse "X"}
    specify { subject.must_parse "X|Y"}
    specify { subject.must_parse "X | Y | Z"}
    specify { subject.must_parse "X | (Y) | Z"}
    specify { subject.must_parse "X       |    (Y | Q)+   |   Z"}
  end

  # SequenceOrDifference ::= (Item ( '-' Item | Item* ))?
  describe "sequence" do
    subject { parser.seq_or_diff }

    specify { subject.must_parse "X" }
    specify { subject.must_parse "X Y" }
    specify { subject.must_parse "X  Y   Z" }
  end

  # Comment ::= '/*' ( [^*] | '*'+ [^*/] )* '*'* '*/'
  describe "comments" do
    subject { parser.comment }

    specify { subject.must_parse "/**/"}
    specify { subject.must_parse "/* */"}
    specify { subject.must_parse "/***/"}
    specify { subject.must_parse "/*****/"}
    specify { subject.must_parse "/*** I'm a comment ****/"}
    specify { subject.must_not_parse "/*/"}
    specify { subject.must_not_parse "// I'm a comment!"}
  end

  # Whitespace ::= S | Comment
  # S          ::= #x9 | #xA | #xD | #x20
  describe "whitespace" do
    subject { parser.whitespace.repeat(1) }

    specify { subject.must_parse " " }
    specify { subject.must_parse "\t" }
    specify { subject.must_parse "\r" }
    specify { subject.must_parse "\n" }
    specify { subject.must_parse "/* comment is whitespace too */"}
    specify { subject.must_parse "    \r\n  \t \n\r\t\t" }
    specify { subject.must_parse "    \r\n  \t /*comment*/\n\r\t\t" }
  end

end