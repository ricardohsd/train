defmodule Train.Agents.VectorPromptSpec do
  @type t :: module()

  @doc """
  A vector prompt must accept the question, context, and metadata
  to be interpolated into the template.
  """
  @callback with(String.t(), String.t(), String.t()) :: String.t()
end
