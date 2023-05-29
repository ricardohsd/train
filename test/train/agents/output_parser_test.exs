defmodule Train.Agents.OutputParserTest do
  use ExUnit.Case, async: true

  alias Train.Agents.OutputParser

  test "parse json markdown" do
    thought =
      "```json\n{\n  \"action\": \"Google search\",\n  \"action_input\": \"Angela Merkel\"\n}\n```"

    action = OutputParser.parse(thought)

    assert action == %{"action" => "Google search", "action_input" => "Angela Merkel"}
  end

  test "parse final answer" do
    thought =
      "{\n  \"action\": \"Final Answer\",\n  \"action_input\": \"Angela Merkel was born in Hamburg, Germany.\"\n}"

    action = OutputParser.parse(thought)

    assert action == %{
             "action" => "Final Answer",
             "action_input" => "Angela Merkel was born in Hamburg, Germany."
           }
  end

  test "return first of multiple actions" do
    thought =
      "```json\n{\n  \"action\": \"Calculator\",\n  \"action_input\": \"Angela Merkel age divided by 2\"\n}\n```\n\n```json\n{\n  \"action\": \"Final Answer\",\n  \"action_input\": \"The capital of Germany is Berlin.\"\n}\n```"

    action = OutputParser.parse(thought)

    assert action == %{
             "action" => "Calculator",
             "action_input" => "Angela Merkel age divided by 2"
           }
  end
end
