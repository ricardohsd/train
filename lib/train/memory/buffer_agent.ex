defmodule Train.Memory.BufferAgent do
  @moduledoc """
  Stores the agent memory to be retrieved in the next call.
  """

  @behaviour Train.Memory.MemorySpec

  use Agent

  alias Train.Memory.Buffer

  @doc """
  Starts the memory agent with a given name. Useful when using it with a DynamicSupervisor.
  """
  def start_link(name) do
    Agent.start_link(fn -> [] end, name: name)
  end

  def start_link() do
    Agent.start_link(fn -> [] end)
  end

  @impl true
  @spec get(pid()) :: list(String.t())
  def get(pid) do
    Agent.get(pid, &Buffer.buffer_history(Enum.reverse(&1)))
  end

  @impl true
  @spec clear(pid()) :: :ok
  def clear(pid) do
    Agent.update(pid, fn _ -> [] end)
  end

  @impl true
  @spec put(pid(), String.t()) :: :ok
  def put(pid, message) do
    Agent.update(pid, &Enum.dedup([message | &1]))
  end

  @spec put_many(pid(), list(String.t())) :: :ok
  def put_many(pid, messages) do
    Agent.update(pid, &Enum.dedup(filter(messages) ++ &1))
  end

  # Don't buffer System messages because they are too repetitive
  # and don't increase context.
  defp filter(messages) do
    messages
    |> Enum.filter(fn %{role: role, content: _} -> role != "system" end)
    |> Enum.reverse()
  end
end
