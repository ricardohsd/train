defmodule Train.Agents.ZeroShotReact.OutputParserTest do
  use ExUnit.Case, async: true

  alias Train.Agents.ZeroShotReact.OutputParser

  test "parse thought and action" do
    resp =
      "Thought: I need to search for the weather forecast in Paris for today and tomorrow.\nAction:\n```json\n{\n  \"action\": \"Google search\",\n  \"action_input\": \"Paris weather forecast today and tomorrow\"\n}\n```"

    action = OutputParser.parse(resp)

    assert [
             {
               "Thought: I need to search for the weather forecast in Paris for today and tomorrow.",
               %{
                 "action" => "Google search",
                 "action_input" => "Paris weather forecast today and tomorrow"
               }
             }
           ] == action
  end

  test "parses first thought and action" do
    resp =
      "Thought: I need to find the weather forecast for Paris for today and tomorrow.\nAction:\n```json\n{\n  \"action\": \"Google search\",\n  \"action_input\": \"Paris weather forecast today and tomorrow\"\n}\n```\nObservation: The weather forecast for Paris today is 10°C with light rain, while tomorrow it will be 11°C with scattered showers.\n\nThought: I now know the weather forecast for Paris today and tomorrow.\nFinal Answer: The weather forecast for Paris tomorrow is 11°C with scattered showers, which is slightly warmer than today's 10°C with light rain."

    action = OutputParser.parse(resp)

    assert [
             {
               "Thought: I need to find the weather forecast for Paris for today and tomorrow.",
               %{
                 "action" => "Google search",
                 "action_input" => "Paris weather forecast today and tomorrow"
               }
             }
           ] == action
  end

  test "parses final answer" do
    resp =
      "Thought: I now know the final answer\nFinal Answer: The weather forecast for tomorrow in Paris is a high of 76°F with a 0% chance of rain during the afternoon and a low of 54°F with a 2% chance of rain overnight. Today's weather in Paris is a high of 78°F and a low of 54°F with 7 mph wind and 55% humidity. So, tomorrow's weather is slightly cooler than today's, but both days have a low chance of rain."

    action = OutputParser.parse(resp)

    assert [
             {
               "Thought: I now know the final answer",
               %{
                 "action" => "Final Answer",
                 "action_input" =>
                   "The weather forecast for tomorrow in Paris is a high of 76°F with a 0% chance of rain during the afternoon and a low of 54°F with a 2% chance of rain overnight. Today's weather in Paris is a high of 78°F and a low of 54°F with 7 mph wind and 55% humidity. So, tomorrow's weather is slightly cooler than today's, but both days have a low chance of rain."
               }
             }
           ] == action
  end

  test "parses multiple actions" do
    resp =
      "Action: \n```json\n[\n  {\n    \"action\": \"Google search\",\n    \"action_input\": \"Leo DiCaprio girlfriend\"\n  },\n  {\n    \"action\": \"Calculator\",\n    \"action_input\": \"23.5 ^ 0.43\"\n  }\n]\n```\nObservation: Camila Morrone is Leonardo DiCaprio's girlfriend. The result of raising her current age (23.5) to the 0.43 power is 3.174.\n\nThought: I have found the answer to both questions.\n\nFinal Answer: Camila Morrone's current age raised to the 0.43 power is 3.174."

    action = OutputParser.parse(resp)

    assert [
             {"", %{"action" => "Google search", "action_input" => "Leo DiCaprio girlfriend"}},
             {"", %{"action" => "Calculator", "action_input" => "23.5 ^ 0.43"}}
           ] == action
  end

  # test "parse final answer" do
  #   thought =
  #     "{\n  \"action\": \"Final Answer\",\n  \"action_input\": \"Angela Merkel was born in Hamburg, Germany.\"\n}"

  #   action = OutputParser.parse(thought)

  #   assert action == %{
  #            "action" => "Final Answer",
  #            "action_input" => "Angela Merkel was born in Hamburg, Germany."
  #          }
  # end

  # test "return first of multiple actions" do
  #   thought =
  #     "```json\n{\n  \"action\": \"Calculator\",\n  \"action_input\": \"Angela Merkel age divided by 2\"\n}\n```\n\n```json\n{\n  \"action\": \"Final Answer\",\n  \"action_input\": \"The capital of Germany is Berlin.\"\n}\n```"

  #   action = OutputParser.parse(thought)

  #   assert action == %{
  #            "action" => "Calculator",
  #            "action_input" => "Angela Merkel age divided by 2"
  #          }
  # end
end
