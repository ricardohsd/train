defmodule Train.Agents.PromptSpec do
  @type t :: module()

  @doc """
  Returns the raw prompt template for the given context.
  """
  @callback for(atom()) :: String.t()
end
