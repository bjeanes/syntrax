# Using phantomjs to leverage an existing railroad/syntax diagram library. It's
# written in Javascript and relies on the DOM. PhantomJS lets me leverage that
# library for now, until I write the SVG rendering logic myself.
require 'phantomjs'
require 'tempfile'

module Diagram
  RAILROAD_LIB = File.expand_path('../../../vendor/railroad-diagrams-js/railroad-diagrams.js', __FILE__ )
  RAILROAD_CSS = File.expand_path('../../../vendor/railroad-diagrams-js/railroad-diagrams.css', __FILE__ )

  class << self
    def render(data)
      script = Tempfile.new(['script', '.js'])
      script << %Q[
        try {
            phantom.onError = function() { phantom.exit(1); };
            phantom.injectJs("#{RAILROAD_LIB}");
            svg = Diagram(#{transform(data)});
            svg.attrs.version = "1.1";
            svg.attrs.xmlns = "http://www.w3.org/2000/svg";
            console.log('<?xml version="1.0" standalone="no"?>');
            console.log("<!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>");
            console.log(svg.toString());
            phantom.exit();
        } catch(err) {
            phantom.exit(1);
        }
      ]
      script.close
      svg = Phantomjs.run(script.path)
      svg.sub /(<svg.*?>)/, %Q{
        \\1
        <defs>
        <style type="text/css">
        @namespace "http://www.w3.org/2000/svg";

        #{File.read(RAILROAD_CSS)}
        </style>
        </defs>
      }
    end

    private

    # E.g. `data` for a JSON-esque array:
    #
    # [
    #   "(",
    #   {
    #     optional: [
    #       :item,
    #       {
    #         zero_or_more: [
    #           ",",
    #           :item
    #         ]
    #       },
    #     ],
    #   },
    #   ")"
    # ]
    def transform(data)
      case data
      when Set    # choice
        data = data.map { |i| transform(i) }
        "Choice(0, #{data.join(', ')})"
      when Array  # sequence
        data = data.map { |i| transform(i) }
        "Sequence(#{data.join(', ')})"
      when Symbol # non-terminal
        "NonTerminal('#{data}')"
      when String # terminal
        "Terminal(#{data.inspect})"
      when Hash   # how to treat value
        value = data.values.first
        case data.keys.first
        when :optional
          "Optional(#{transform(value)})"
        when :zero_or_more
          "ZeroOrMore(#{transform(value)})"
        when :one_or_more
          "OneOrMore(#{transform(value)})"
        end
      end
    end
  end
end
