defmodule Train.Memory.BufferTokenWindowAgent do
  @moduledoc """
  Buffers last conversation messages without reaching the max tokens.
  """

  @behaviour Train.Memory.MemorySpec

  use Agent

  alias Train.Memory.Buffer

  @doc """
  Starts the memory agent with a given name. Useful when using it with a DynamicSupervisor.
  """
  def start_link(name, max_tokens) do
    Agent.start_link(fn -> {[], max_tokens} end, name: name)
  end

  def start_link(max_tokens \\ 500) do
    Agent.start_link(fn -> {[], max_tokens} end)
  end

  @impl true
  @spec get(pid()) :: list(String.t())
  def get(pid) do
    Agent.get(pid, fn {val, _max_tokens} -> Enum.reverse(val) end)
  end

  @impl true
  @spec clear(pid()) :: :ok
  def clear(pid) do
    Agent.update(pid, fn {_, max_tokens} -> {[], max_tokens} end)
  end

  @impl true
  @spec put(pid(), String.t()) :: :ok
  def put(pid, message) do
    Agent.update(pid, fn {buffer, max_tokens} ->
      {
        prune_messages([message], buffer, max_tokens),
        max_tokens
      }
    end)
  end

  @spec put_many(pid(), list(String.t())) :: :ok
  def put_many(pid, messages) do
    Agent.update(pid, fn {buffer, max_tokens} ->
      {
        prune_messages(messages, buffer, max_tokens),
        max_tokens
      }
    end)
  end

  defp prune_messages(messages, buffer, max_tokens) do
    new_messages =
      messages
      |> filter()
      |> Enum.reverse()
      |> Enum.concat(buffer)
      |> Enum.dedup()

    take_while_max_tokens(new_messages, max_tokens)
  end

  defp take_while_max_tokens(messages, max_tokens) do
    fun = fn entry, acc ->
      text = [entry | acc] |> Buffer.buffer_history() |> Enum.join("\n")
      {:ok, tokens} = ExTiktoken.CL100K.encode(text)
      length(tokens) < max_tokens
    end

    {_, res} =
      Enum.reduce(messages, {:cont, []}, fn entry, it ->
        case it do
          {:cont, acc} ->
            if fun.(entry, acc) do
              {:cont, [entry | acc]}
            else
              {:halt, acc}
            end

          {:halt, acc} ->
            {:halt, acc}
        end
      end)

    res |> Enum.reverse()
  end

  # Don't buffer System messages because they are too repetitive
  # and don't increase context.
  defp filter(messages) do
    messages
    |> Enum.filter(fn %{role: role, content: _} -> role != "system" end)
  end
end
