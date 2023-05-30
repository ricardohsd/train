defmodule Train.Agents.PromptSpec do
  @type t :: module()

  @doc """
  Returns the raw prompt template.
  """
  @callback to_s() :: String.t()
end
