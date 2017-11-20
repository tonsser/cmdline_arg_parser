module CmdlineArgParser
  class ReadmeBuilder
    def initialize(parser:, specifics:)
      @parser = parser
      @specifics = specifics
    end

    def build
      output = <<-EOS
# #{@specifics.title}

#{@specifics.description}

## Subcommands

    EOS

      subcommand_descriptions = @parser.subcommands.map do |subcommand|
        subcommand_description = <<-EOS
$ #{@specifics.script_name} #{subcommand.command}
  #{@specifics.description_for_subcommand(subcommand.command)}
        EOS

        if subcommand.options != [] || subcommand.switches != []
          subcommand_description += indent("\n## Options\n", 2)

          option_descriptions = subcommand.options.map do |option|
            option_label = @specifics.option_label_for(
              subcommand: subcommand.command,
              option_key: option.long_key,
            )

            lines = []
            lines << "--#{option.long_key} #{option_label}"

            if option.short_key
              lines << "-#{option.short_key} #{option_label}"
            end

            option_description = @specifics.option_description(
              subcommand: subcommand.command,
              option_key: option.long_key,
            )
            lines << indent("#{option_description}\n", 2)

            lines.join("\n")
          end

          switch_descriptions = subcommand.switches.map do |switch|
            lines = []
            lines << "--#{switch.long_key}"
            if switch.short_key
              lines << "-#{short_key.long_key}"
            end
            lines << @specifics.switch_label(
              subcommand: subcommand.command,
              switch_key: switch.long_key,
            )
            lines.join("\n")
          end

          subcommand_description += indent(option_descriptions.join("\n"), 4)
          subcommand_description += indent(switch_descriptions.join("\n"), 4)
        end

        indent(subcommand_description, 2)
      end
      output += subcommand_descriptions.join("\n")

      output.chomp
    end

    private

    def indent(str, amount)
      str.lines.map do |line|
        "#{' ' * amount}#{line}"
      end.join
    end
  end
end
