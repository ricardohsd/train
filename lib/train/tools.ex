defmodule Train.Tools do
  def run_action(action, tools) do
    tool =
      Enum.find(tools, fn t ->
        t.name() == action["action"]
      end)

    if action["action"] == "Final Answer" do
      action["action_input"]
    else
      {:ok, res} = tool.query(action["action_input"])
      res
    end
  end

  def tool_descriptions(tools) do
    Enum.map(tools, fn tool ->
      "> #{tool.name()} #{tool.description()}"
    end)
    |> Enum.join("\n")
  end

  def tool_names(tools) do
    Enum.map(tools, fn tool -> tool.name() end)
    |> Enum.join(", ")
  end
end
