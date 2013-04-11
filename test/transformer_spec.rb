require 'bundler'
Bundler.setup(:default, :test)

require 'minitest/autorun'

require_relative "../lib/syntrax/ebnf_parser"
require_relative "../lib/syntrax/transformer"

describe Transformer do
  def transform(rule)
    parsed = EbnfParser.new.parse(rule)
    Transformer.new.apply(parsed)
  end

  specify do
    rule = "Foo ::= Bar"
    transform(rule).must_equal Foo: [:Bar]
  end

  specify do
    rule = "S ::= 'str'"
    transform(rule).must_equal S: ['str']
  end

  specify do
    rule = "Str ::= '\"' 'str' '\"'"
    transform(rule).must_equal Str: ['"', 'str', '"']
  end

  specify do
    rule = "Or ::= A | B | '123'"
    transform(rule).must_equal Or: Set.new([:A, :B, '123'])
  end

  specify do
    rule = "Repeat ::= A?"
    transform(rule).must_equal Repeat: {optional: [:A]}
  end

  specify do
    rule = "Repeat ::= A+"
    transform(rule).must_equal Repeat: {one_or_more: [:A]}
  end

  specify do
    rule = "Repeat ::= A*"
    transform(rule).must_equal Repeat: {zero_or_more: [:A]}
  end

  specify do
    rule = "List ::= '(' (Number | String | List | Map | Vector)* ')'"
    transform(rule).must_equal(List: [
        "(",
        {
          zero_or_more: Set.new([:Number, :String, :List, :Map, :Vector])
        },
        ")"
      ])
  end

  specify do
    rule = <<-EBNF
      Map ::= '{' (Anything Anything)* '}'
      String ::= '"' Anything* '"' | "'" Anything* "'"
      List ::= '(' (Number | String | List | Map | Vector)* ')'
    EBNF

    transform(rule).must_equal(
      Map: ["{", {zero_or_more: [:Anything, :Anything]}, "}"],
      String: Set.new([
          ["'", {zero_or_more: [:Anything]}, "'"],
          ['"', {zero_or_more: [:Anything]}, '"'],
        ]),
      List: [
        "(",
        {zero_or_more: Set.new([:Number, :String, :List, :Map, :Vector])},
        ")"
      ])
  end
end
