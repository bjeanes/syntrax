require 'bundler'
Bundler.setup(:default, :test)

require 'minitest/autorun'

require_relative "../lib/syntrax/transformer"

describe Transformer do
  def transform(rule)
    parsed = EbnfParser.new.parse(rule)
    Transformer.new.apply(parsed)
  end

  specify do
    rule = "Foo ::= Bar"
    transform(rule).must_equal [:Bar]
  end

  specify do
    rule = "S ::= 'str'"
    transform(rule).must_equal ['str']
  end

  specify do
    rule = "Str ::= '\"' 'str' '\"'"
    transform(rule).must_equal ['"', 'str', '"']
  end
end
