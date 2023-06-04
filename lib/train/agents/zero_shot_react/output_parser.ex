defmodule Train.Agents.ZeroShotReact.OutputParser do
  def parse(text) do
    text
    |> _parse()
    |> List.wrap()
  end

  defp _parse(text) do
    cleaned = text |> String.trim()

    cond do
      String.match?(cleaned, ~r/Action:/) ->
        parse_action(cleaned)

      String.match?(cleaned, ~r/Final Answer:/) ->
        parse_final_answer(cleaned)

      true ->
        nil
    end
  end

  def parse_action(text) do
    [thought | actions] = String.split(text, "Action:")
    actions = actions |> Enum.join("") |> String.trim()

    actions
    |> Train.Agents.OutputParser.parse()
    |> List.wrap()
    |> Enum.map(fn action ->
      {
        String.trim(thought),
        action
      }
    end)
  end

  def parse_final_answer(text) do
    [thought, final_answer] = String.split(text, "Final Answer: ")

    {
      String.trim(thought),
      %{
        "action" => "Final Answer",
        "action_input" => String.trim(final_answer)
      }
    }
  end
end
