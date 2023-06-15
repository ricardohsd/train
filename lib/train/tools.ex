defmodule Train.Tools do
  alias Train.LlmChain

  @type tool_wrapper :: %{}

  @spec run_action(map(), LlmChain.t()) :: {:error, any()} | {:ok, String.t()}
  def run_action(action, %LlmChain{tools: tools} = chain) do
    tool =
      Enum.find(tools, fn t ->
        t.name() == action["action"]
      end)

    if action["action"] == "Final Answer" do
      {:ok, action["action_input"]}
    else
      run_tool(tool, action["action_input"], chain)
    end
  end

  @spec run_tool(tool_wrapper(), String.t(), LlmChain.t()) ::
          {:error, String.t()} | {:ok, String.t()}
  def run_tool(%{name: name, func: tool}, input, chain) do
    case tool.query(input, chain) do
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
