require 'parslet'
require 'set'

class Transformer < Parslet::Transform
  rule(name: simple(:name)) { name.to_s.to_sym }
  rule(string: simple(:string)) { string.to_s }
  rule(primary: simple(:primary)) { primary }
  rule(primary: simple(:primary), how_many: '?') { {optional: [primary]} }
  rule(primary: simple(:primary), how_many: '*') { {zero_or_more: [primary]} }
  rule(primary: simple(:primary), how_many: '+') { {one_or_more: [primary]} }
  rule(name: simple(:name), definition: {option: sequence(:definition)}) { definition }
  rule(name: simple(:name), definition: {option: simple(:definition)}) { [definition] }
  rule(name: simple(:name), definition: subtree(:options)) {
    if Array === options
      Set.new(options.map { |x| x[:option] })
    else
      options[:option]
    end
  }
  rule(production: subtree(:production)) { production }
end
