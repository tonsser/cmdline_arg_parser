module CmdlineArgParser
  module Dsl
    def subcommand(name, &block)
      @subcommands ||= []

      subcommand_dsl = SubcommandDsl.new
      if block
        subcommand_dsl.instance_eval(&block)
      end

      @subcommands << Parser::Subcommand.new(
        name,
        options: subcommand_dsl.options,
        switches: subcommand_dsl.switches,
      )
    end

    def parse(argv)
      parser.parse(argv)
    end

    def build_readme(builder)
      parser.build_readme(builder)
    end

    def parser
      @subcommands ||= []
      @parser ||= Parser.new(subcommands: @subcommands)
    end

    class SubcommandDsl
      def initialize
        @options = []
        @switches = []
      end

      attr_reader :options, :switches

      def option(name, default: nil, multiple: false, short_key: nil, &block)
        @options << Parser::Option.new(
          name,
          multiple: multiple,
          short_key: short_key,
          default: default,
          &block
        )
      end

      def switch(name, short_key: nil)
        @switches << Parser::Switch.new(name, short_key: short_key)
      end
    end
  end
end
