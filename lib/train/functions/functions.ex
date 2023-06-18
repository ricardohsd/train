defmodule Train.Functions do
  alias Train.Tools

  @spec format_tools(Tools.Spec.t()) :: map()
  def format_tools(tools) do
    Enum.map(tools, fn tool -> tool.to_func() end)
  end

  @doc """
  Get tool with the name, or return first tool when name is null.
  """
  @spec get_tool(list(Tools.Spec.t()), String.t()) :: Tools.Spec.t()
  def get_tool(tools, nil) do
    List.first(tools)
  end

  def get_tool(tools, name) do
    Enum.find(tools, fn tool ->
      tool.to_func()[:name] == name
    end)
  end
end
