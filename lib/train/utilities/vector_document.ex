defmodule Train.Utilities.VectorDocument do
  @moduledoc """
  Creates a single document from the vector db's response (Pinecone).
  """

  defstruct text: nil, metadata: nil

  def parse({:ok, %{"matches" => _} = vector}) do
    parse(vector)
  end

  def parse(%{"matches" => matches}) do
    text =
      Enum.reduce(matches, "", fn m, acc -> m["metadata"]["text"] <> acc <> "\n" end)
      |> String.trim()

    metadata =
      Enum.reduce(matches, "", fn m, acc -> reduce_metadata(m["metadata"]) <> acc <> "\n" end)
      |> String.trim()

    %__MODULE__{text: text, metadata: metadata}
  end

  def parse({:error, _}) do
  end

  def reduce_metadata(%{"metadata" => metadata}) do
    metadata
  end

  def reduce_metadata(metadata) do
    metadata
    |> Enum.reject(fn {k, v} -> v == "Not defined" || k == "text" end)
    |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
    |> Jason.encode!()
  end
end
