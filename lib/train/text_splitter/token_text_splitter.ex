defmodule Train.TextSplitter.TokenTextSplitter do
  @moduledoc """
  Split the given text by tokens.
  """
  def split(text, chunk_size \\ 1000) do
    {:ok, tokens} = ExTiktoken.CL100K.encode(text)

    tokens
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(fn chunks ->
      {:ok, chunk_text} = ExTiktoken.CL100K.decode(chunks)
      chunk_text
    end)
  end
end
