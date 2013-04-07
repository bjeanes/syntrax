require 'parslet'
require 'set'

class Transformer < Parslet::Transform
  rule(name: simple(:name)) { name.to_s.to_sym }
  rule(string: simple(:string)) { string.to_s }
  rule(primary: simple(:primary)) { primary }
  rule(name: simple(:name), definition: {option: sequence(:definition)}) { definition }
  rule(name: simple(:name), definition: {option: simple(:definition)}) { [definition] }
  rule(name: simple(:name), definition: subtree(:options)) { Set.new(options.map { |x| x[:option] }) }
  rule(production: subtree(:production)) { production }
end
