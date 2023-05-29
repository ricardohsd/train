defmodule Train.Agents.PromptSpec do
  @type t :: module()

  @doc """
  Defines the system message.
  """
  @callback system_message() :: String.t()

  @doc """
  Defines the human message.
  """
  @callback human_message() :: String.t()
end
