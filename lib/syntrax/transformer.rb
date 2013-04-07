require 'parslet'

class Transformer < Parslet::Transform
  rule(primary: simple(:primary)) { primary.to_s }
  rule(name: simple(:name), definition: sequence(:definition)) { definition }
  rule(production: sequence(:production)) { production }
end
