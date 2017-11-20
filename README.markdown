# Command-line argument parser

A small library for parsing command-line arguments in Ruby.

Designed to be used with command-line tools like `git` which have a set of subcommands that each have different options and switches.

[On rubygems.org](https://rubygems.org/gems/cmdline_arg_parser)

## Sample

```ruby
require "cmdline_arg_parser"

# Define a parser using the DSL
class ParserFromDsl
  extend CmdlineArgParser::Dsl

  subcommand "merge" do
    option "branches", multiple: true, short_key: "b"
    option "into", default: "master"
    option("from-step") { |value| value.to_i }
    switch "dry-run"
  end

  subcommand "version"
end

# Have some ARGV
ARGV = ["merge", "--dry-run", "--from-step", "10", "-b", "release-branch", "other-branch"]

args = ParserFromDsl.parse(ARGV)

# Accessing the parsed data
args.subcommand # => "merge"
args.options # => { "into" => "master", "branches" => ["release-branch", "other-branch"], "from-step" => 10 }
args.switches # => Set.new(["dry-run"])
```

If you don't want to use the DSL, the above parser can also be written as:

```ruby
parser = CmdlineArgParser::Parser.new(
  subcommands: [
    CmdlineArgParser::Parser::Subcommand.new(
      "merge",
      options: [
        CmdlineArgParser::Parser::Option.new("branches", multiple: true, short_key: "b"),
        CmdlineArgParser::Parser::Option.new("into", default: "master"),
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

### Readme generation

TODO

## Installation

Add this line to your application's Gemfile:

```ruby
gem "cmdline_arg_parser"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cmdline_arg_parser

## Built by

[@davidpdrsn](https://twitter.com/davidpdrsn)
