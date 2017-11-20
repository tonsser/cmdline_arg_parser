# Command-line argument parser

A small library for parsing command-line arguments in Ruby.

Designed to be used with command-line tools like `git` which have a set of subcommands that each have different options and switches.

## Sample

```ruby
require "cmdline_arg_parser"

# Define a parser using the DSL
class ParserFromDsl
  extend CmdlineArgParser::Dsl

  subcommand "merge" do
    option "branch", short_key: "b"
    option("from-step") { |value| value.to_i }
    switch "dry-run"
  end

  subcommand "version"
end

# Have some ARGV
ARGV = ["merge", "--dry-run", "--from-step", "10", "-b", "release-branch"]

args = ParserFromDsl.parse(ARGV)

# Accessing the parsed data
args.subcommand # => "merge"
args.options # => { "branch" => "release-branch", "from-step" => 10 }
args.switches # => Set.new(["dry-run"])
```

If you don't want to use the DSL, the above parser can also be written as:

```ruby
parser = CmdlineArgParser::Parser.new(
  subcommands: [
    CmdlineArgParser::Parser::Subcommand.new(
      "merge",
      options: [
        CmdlineArgParser::Parser::Option.new("branch", short_key: "b"),
        CmdlineArgParser::Parser::Option.new("from-step") { |value| value.to_i },
      ],
      switches: [
        CmdlineArgParser::Parser::Switch.new("dry-run"),
      ],
    ),
    CmdlineArgParser::Parser::Subcommand.new("version"),
  ]
)
```

## Built by

[@davidpdrsn](https://twitter.com/davidpdrsn)
