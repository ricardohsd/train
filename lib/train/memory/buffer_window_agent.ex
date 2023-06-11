defmodule Train.Memory.BufferWindowAgent do
  @moduledoc """
  Buffers the last X messages to be retrieved in the next call to the LLM.
  """

  @behaviour Train.Memory.MemorySpec

  use Agent

  alias Train.Memory.Buffer

  @doc """
  Starts the memory agent with a given name. Useful when using it with a DynamicSupervisor.
  """
  def start_link(name, window_size) do
    Agent.start_link(fn -> {[], window_size} end, name: name)
  end

  def start_link(window_size \\ 2) do
    Agent.start_link(fn -> {[], window_size} end)
  end

  @impl true
  @spec get(pid()) :: list(String.t())
  def get(pid) do
    Agent.get(pid, fn {val, _window} -> Enum.reverse(val) end)
  end

  @impl true
  @spec clear(pid()) :: :ok
  def clear(pid) do
    Agent.update(pid, fn {_, window} -> {[], window} end)
  end

  @impl true
  @spec put(pid(), String.t()) :: :ok
  def put(pid, message) do
    Agent.update(pid, fn {val, window} ->
      {
        [message | val]
        |> filter()
        |> Enum.dedup()
        |> Enum.take(window),
        window
      }
    end)
  end

  @spec put_many(pid(), list(String.t())) :: :ok
  def put_many(pid, messages) do
    Agent.update(pid, fn {val, window} ->
      {
        messages
        |> filter()
        |> Enum.reverse()
        |> Enum.concat(val)
        |> Enum.dedup()
        |> Enum.take(window),
        window
      }
    end)
  end

  # Don't buffer System messages because they are too repetitive
  # and don't increase context.
  defp filter(messages) do
    messages
    |> Enum.filter(fn %{role: role, content: _} -> role != "system" end)
  end
end
