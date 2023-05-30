defmodule Train.TextSplitter.CharacterSplitter do
  import Train.TextSplitter.TextSplitter

  @doc """
  Split the text with the given separator.
  The result will be merged recursively, and with an overlap when given.
  """
  def split_text(text, %{chunk_size: _, overlap: _, separator: _} = opts) do
    _split_text(text, opts)
  end

  def split_text(text, %{chunk_size: _, separator: _} = opts) do
    _split_text(text, Map.put(opts, :overlap, 0))
  end

  defp _split_text(text, %{chunk_size: chunk_size, overlap: overlap, separator: separator}) do
    splits =
      if separator do
        String.split(text, separator)
      else
        [text]
      end

    merge(splits, chunk_size, overlap, separator)
  end
end
