require "set"
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

      argv = expand_shorthand_switches(argv)

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

    private

    def expand_shorthand_switches(argv)
      argv.flat_map do |arg|
        if arg =~ /^-[a-z]/
          arg[1..-1].split("").map { |arg| "-#{arg}" }
        else
          arg
        end
      end
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
      def initialize(long_key, default: nil, multiple: false, short_key: nil, &block)
        if short_key && short_key.length != 1
          raise ArgumentError, "`short_key` can only be one character, was #{short_key.inspect}"
        end

        @long_key = long_key
        @short_key = short_key
        @multiple = multiple
        @default = default
        @block = block
      end

      attr_reader :short_key, :long_key

      def parse(argv, out)
        index_of_key = argv.find_index do |word|
          word == "--#{@long_key}" || word == "-#{@short_key}"
        end

        if index_of_key.nil?
          if @default.nil?
            msg = "Missing argument --#{@long_key}"
            if @short_key
              msg += " or -#{@short_key}"
            end
            raise ParseError, msg
          else
            out.set_option(@long_key, @default)
            return
          end
        end

        index_of_value = index_of_key + 1

        if @multiple
          argv.delete_at(index_of_key)
          values = argv.take_while { |value| !(value =~ /^-/) }
          values.length.times { argv.delete_at(0) }

          if @block
            values = values.map { |value| @block.call(value) }
          end
          out.set_option(@long_key, values)
        else
          value = argv[index_of_value]
          if @block
            value = @block.call(value)
          end
          out.set_option(@long_key, value)
          argv.delete_at(index_of_key)
          argv.delete_at(index_of_value - 1)
        end
      end
    end

    class Switch
      def initialize(long_key, short_key: nil)
        if short_key && short_key.length != 1
          raise ArgumentError, "`short_key` can only be one character"
        end

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
          argv.delete_at(index_of_key)
        end
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
