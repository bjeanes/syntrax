require 'parslet'

class Transformer < Parslet::Transform
  rule(name: simple(:name)) { name.to_s.to_sym }
  rule(string: simple(:string)) { string.to_s }
  rule(primary: simple(:primary)) { primary }
  rule(name: simple(:name), definition: sequence(:definition)) { definition }
  rule(name: simple(:name), definition: simple(:definition)) { [definition] }
  rule(production: sequence(:production)) { production }
end
