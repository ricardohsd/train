defmodule Train.Memory.Buffer do
  @doc """
  Buffers the history of messages sent to the LLM.
  """
  def buffer_history([]) do
    []
  end

  def buffer_history([head | tail]) do
    [_buffer(head) | buffer_history(tail)] |> Enum.reject(&is_nil/1)
  end

  # The initial system's prompt doesn't need
  # to be attached as it is already included
  defp _buffer(%{role: "system", content: _content}) do
    nil
  end

  defp _buffer(%{role: "assistant", content: content}) do
    "AI: #{content}"
  end

  defp _buffer(%{role: "user", content: content}) do
    "Human: #{content}"
  end
end
