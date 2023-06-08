defmodule Train.Memory.MemorySpec do
  @type t :: module()

  @callback get(pid()) :: list(String.t())

  @callback clear(pid()) :: :ok

  @callback put(pid(), String.t()) :: :ok
end
