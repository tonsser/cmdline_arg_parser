require "test_helper"

class CmdlineArgParserTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::CmdlineArgParser::VERSION
  end

  def test_parsing_args_with_one_subcommand
    parser = CmdlineArgParser::Parser.new(
      subcommands: [CmdlineArgParser::Parser::Subcommand.new("help")],
    )

    assert_parser_result(
      parser,
      command: "api-git help",
      subcommand: "help",
    )
  end

  def test_parsing_subcommand_with_two_options
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

    assert_parser_result(
      parser,
      command: "api-git merge --dry-run --from-step 10 -b release-branch",
      subcommand: "merge",
      options: { "branch" => "release-branch", "from-step" => 10 },
      switches: ["dry-run"],
    )

    assert_parser_result(
      parser,
      command: "api-git version",
      subcommand: "version",
      options: {},
      switches: [],
    )
  end

  def test_building_readme
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
            CmdlineArgParser::Parser::Switch.new("foobar"),
          ],
        ),
        CmdlineArgParser::Parser::Subcommand.new("version"),
      ]
    )

    readme_builder = Class.new do
      def title
        "Tonsser API Git helpers"
      end

      def description
        "Helper script for doing common git operations"
      end

      def script_name
        "api-git"
      end

      def description_for_subcommand(name)
        {
          "merge" => "Make new branch from master",
          "version" => "Print version number",
        }.fetch(name)
      end

      def option_label_for(subcommand:, option_key:)
        {
          "merge" => {
            "branch" => "BRANCH",
            "from-step" => "STEP",
          }
        }.fetch(subcommand).fetch(option_key)
      end

      def option_description_for(subcommand:, option_key:)
        {
          "merge" => {
            "branch" => "Name of branch to merge into",
            "from-step" => <<-EOS.chomp
            Run through the commands starting at step number STEP. Zero indexed.
              This can be used when something breaks halfway through and you want
            to continue from a certain point after having fixed the problem.
              EOS
          }
        }.fetch(subcommand).fetch(option_key)
      end

      def switch_label_for(subcommand:, switch_key:)
        {
          "merge" => {
            "dry-run" => "Don't actually do anything",
            "foobar" => "Another switch",
          }
        }.fetch(subcommand).fetch(switch_key)
      end
    end.new

    parser.build_readme(readme_builder)

    # actual = parser.build_readme(readme_builder)
    # puts actual
    # raise "Just testing"
  end

  class ParserFromDsl
    extend CmdlineArgParser::Dsl

    subcommand "merge" do
      option "branch", short_key: "b"
      option("from-step") { |value| value.to_i }
      switch "dry-run"
    end

    subcommand "version"
  end

  def test_building_with_dsl
    assert_parser_result(
      ParserFromDsl,
      command: "api-git merge --dry-run --from-step 10 -b release-branch",
      subcommand: "merge",
      options: { "branch" => "release-branch", "from-step" => 10 },
      switches: ["dry-run"],
    )
  end

  def test_parsing_multiple_values_to_one_arg
    parser = Class.new do
      extend CmdlineArgParser::Dsl

      subcommand "merge" do
        option "branches", multiple: true, short_key: "b"
      end
    end

    assert_parser_result(
      parser,
      command: "api-git merge -b master develop",
      subcommand: "merge",
      options: { "branches" => ["master", "develop"] },
    )
  end

  def test_parse_with_defaults
    parser = Class.new do
      extend CmdlineArgParser::Dsl

      subcommand "merge" do
        option "branch", short_key: "b"
        option "into", short_key: "i", default: "master"
      end
    end

    assert_parser_result(
      parser,
      command: "api-git merge -b develop",
      subcommand: "merge",
      options: { "branch" => "develop", "into" => "master" },
    )

    assert_parser_result(
      parser,
      command: "api-git merge -b develop -i staging",
      subcommand: "merge",
      options: { "branch" => "develop", "into" => "staging" },
    )
  end

  def test_with_optional_switch
    parser = Class.new do
      extend CmdlineArgParser::Dsl

      subcommand "production" do
        switch "dry-run"
      end
    end

    assert_parser_result(
      parser,
      command: "api-git production",
      subcommand: "production",
      options: {},
      switches: [],
    )
  end

  private

  def assert_parser_result(parser, command:, subcommand: nil, options: nil, switches: nil)
    args = parser.parse(to_argv(command))

    if subcommand
      assert_equal(subcommand, args.subcommand, "subcommand failed")
    end

    if options
      assert_equal(options, args.options, "options failed")
    end

    if switches
      assert_equal(Set.new(switches), args.switches, "switches failed")
    end
  end

  def to_argv(command)
    command.split(" ")[1..-1]
  end
end
