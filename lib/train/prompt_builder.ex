defmodule Train.PromptBuilder do
  @doc """
  Builds a chat's system promp by joining the system, human, and AI prompts.
  """
  def build(messages) do
    _build(messages) |> Enum.join("\n")
  end

  defp _build([]) do
    []
  end

  defp _build([{:system, message} | tail]) do
    ["System: #{message}" | _build(tail)]
  end

  defp _build([{:human, message} | tail]) do
    ["Human: #{message}" | _build(tail)]
  end

  defp _build([{:ai, message} | tail]) do
    ["AI: #{message}" | _build(tail)]
  end

  defp _build([{role, message} | tail]) do
    ["#{role}: #{message}" | _build(tail)]
  end
end
