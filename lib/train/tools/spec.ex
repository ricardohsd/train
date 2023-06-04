defmodule Train.Tools.Spec do
  @type t :: module()

  @doc """
  Async query the given tool and return the result or error.
  """
  @callback query(String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
