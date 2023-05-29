defmodule Train.Memory.BufferAgent do
  @moduledoc """
  Stores the agent memory to be retrieved in the next call.
  """

  use Agent

  alias Train.Memory.Buffer

  def start_link(initial_value \\ []) do
    Agent.start_link(fn -> initial_value end)
  end

  @spec get(pid()) :: list(String.t())
  def get(pid) do
    Agent.get(pid, &Buffer.buffer_history(Enum.reverse(&1)))
  end

  @spec clear(pid()) :: :ok
  def clear(pid) do
    Agent.update(pid, fn _ -> [] end)
  end

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
