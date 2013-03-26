require 'parslet'

module MiniTest::Expectations
  def must_parse(input)
    MiniTest::Spec.current.assert !!self.parse(input)
  rescue Parslet::ParseFailed => ex
    MiniTest::Spec.current.assert false,
      "Expected #{inspect} to be able to parse #{input.inspect}.\n\n#{ex.cause.ascii_tree}"
  end
end