defmodule Train.ToolSpec do
  @type t :: module()

  @doc """
  Async query the given tool and return the result or error.
  """
  @callback query(String.t()) :: {:ok, any} | {:error, any}

  @callback name() :: String.t()

  @callback description() :: String.t()
end
