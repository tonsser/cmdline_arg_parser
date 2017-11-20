require "cmdline_arg_parser/version"
require "cmdline_arg_parser/readme_builder"
require "cmdline_arg_parser/dsl"

module CmdlineArgParser
  class Parser
    class ParseError < RuntimeError; end

    def initialize(subcommands:)
      @subcommands = subcommands
    end

    attr_reader :subcommands

    def parse(argv)
      parsed_args = ParsedArgs.new

      @subcommands.each do |subcommand|
        subcommand.try_parse(argv, parsed_args)
      end

      unless argv == []
        raise ParseError, "Expected end of input, but got \"#{argv.join(' ')}\""
      end

      parsed_args
    end

    def build_readme(builder)
      ReadmeBuilder.new(parser: self, specifics: builder).build
    end

    class Subcommand
      def initialize(command, options: [], switches: [])
        @command = command
        @options = options
        @switches = switches
      end

      attr_reader :command, :options, :switches

      def try_parse(argv, out)
        return unless argv[0] == @command

        out.subcommand = argv.shift
        @options.each { |option| option.parse(argv, out) }
        @switches.each { |switch| switch.parse(argv, out) }
      end
    end

    class Option
      def initialize(long_key, short_key: nil, &block)
        @long_key = long_key
        @short_key = short_key
        @block = block
      end

      attr_reader :short_key, :long_key

      def parse(argv, out)
        index_of_key = argv.find_index do |word|
          word == "--#{@long_key}" || word == "-#{@short_key}"
        end
        index_of_value = index_of_key + 1

        value = argv[index_of_value]
        if @block
          value = @block.call(value)
        end
        out.set_option(@long_key, value)

        argv.delete_at(index_of_key)
        argv.delete_at(index_of_value - 1)
      end
    end

    class Switch
      def initialize(long_key, short_key: nil)
        @long_key = long_key
        @short_key = short_key
      end

      attr_reader :long_key, :short_key

      def parse(argv, out)
        index_of_key = argv.find_index do |word|
          word == "--#{@long_key}" || word == "-#{@short_key}"
        end

        if index_of_key
          out.set_switch(@long_key)
        end

        argv.delete_at(index_of_key)
      end
    end
  end

  class ParsedArgs
    attr_reader(
      :subcommand,
    )

    attr_writer(
      :subcommand,
      :options,
      :switches,
    )

    def options
      @options ||= {}
    end

    def switches
      @switches ||= Set.new
    end

    def set_option(key, value)
      @options ||= {}
      @options[key] = value
    end

    def set_switch(key)
      @switches ||= Set.new
      @switches << key
    end
  end
end
