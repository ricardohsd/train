defmodule Train.Tools.Spec do
  alias Train.LlmChain

  @type t :: module()

  @doc """
  Async query the given tool and return the result or error.
  """
  @callback query(String.t(), LlmChain.t()) :: {:ok, String.t()} | {:error, String.t()}
end
