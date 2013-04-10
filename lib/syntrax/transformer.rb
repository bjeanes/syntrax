require 'parslet'
require 'set'

class Transformer < Parslet::Transform
  cardinality = {
    '?' => :optional,
    '+' => :one_or_more,
    '*' => :zero_or_more
  }

  wrap = lambda { |x| Enumerable === x ? x : [x] }

  rule(name: simple(:name), definition: subtree(:definition)) { wrap[definition] }
  rule(name: simple(:name)) { name.to_s.to_sym }
  rule(string: simple(:string)) { string.to_s }
  rule(choice: {option: subtree(:option)}) { option }
  rule(choice: subtree(:choices)) { Set.new(choices.map { |choice| choice[:option] }) }
  rule(production: subtree(:production)) { production }
  rule(primary: subtree(:primary)) { primary }
  rule(primary: subtree(:primary), how_many: simple(:how_many)) {
    value = wrap[primary]
    if (key = cardinality[how_many.to_s])
      {key => value}
    else
      value
    end
  }
end
