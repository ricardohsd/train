defmodule Train.Tools do
  @type tool_wrapper :: %{
          required(:name) => String.t(),
          required(:description) => String.t(),
          required(:func) => Train.Tools.Spec.t()
        }

  @spec run_action(map(), list(tool_wrapper())) :: {:error, any()} | {:ok, String.t()}
  def run_action(action, tools) do
    tool =
      Enum.find(tools, fn t ->
        t.name() == action["action"]
      end)

    if action["action"] == "Final Answer" do
      {:ok, action["action_input"]}
    else
      run_tool(tool, action["action_input"])
    end
  end

  @spec run_tool(tool_wrapper(), String.t()) :: {:error, String.t()} | {:ok, String.t()}
  def run_tool(%{name: name, func: tool}, input) do
    case tool.query(input) do
      {:ok, res} -> {:ok, res}
      {:error, err} -> {:error, "failed to run #{name} with #{err}"}
    end
  end

  @spec tool_descriptions(list(tool_wrapper())) :: String.t()
  def tool_descriptions(tools) do
    Enum.map(tools, fn %{name: name, description: description} ->
      "> #{name} #{description}"
    end)
    |> Enum.join("\n")
  end

  @spec tool_names(list(tool_wrapper())) :: String.t()
  def tool_names(tools) do
    Enum.map(tools, fn %{name: name} -> name end)
    |> Enum.join(", ")
  end
end
