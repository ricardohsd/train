defmodule Train.Agents.OutputParser do
  def parse(texts) when is_list(texts) do
    Enum.map(texts, fn text ->
      parse(text)
    end)
  end

  def parse(text) do
    cleaned = text |> String.trim()

    cleaned =
      if String.contains?(cleaned, "```json") do
        [_ | match] = String.split(cleaned, "```json")
        List.wrap(match) |> List.first()
      else
        cleaned
      end

    cleaned =
      if String.contains?(cleaned, "```") do
        [c, _] = String.split(cleaned, "```")
        c
      else
        cleaned
      end

    with {:ok, json} <- Jason.decode(cleaned) do
      json
    else
      {:error, %Jason.DecodeError{data: data}} ->
        %{"action" => "Final Answer", "action_input" => data}
    end
  end

  def format_instructions() do
    """
    RESPONSE FORMAT INSTRUCTIONS
    ----------------------------

    When responding to me, please output a response in one of two formats:

    **Option 1:**
    Use this if you want the human to use a tool.
    Markdown code snippet formatted in the following schema:

    ```json
    {
      "action": string \\ The action to take. Must be one of {tool_names}
      "action_input": string \\ The input to the action
    }
    ```

    **Option #2:**
    Use this if you want to respond directly to the human. Markdown code snippet formatted in the following schema:

    ```json
    {
      "action": "Final Answer",
      "action_input": string \\ You should put what you want to return to use here
    }
    ```
    """
    |> String.trim()
  end
end
