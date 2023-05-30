defmodule Train.TextSplitter.RecursiveTextSplitter do
  import Train.TextSplitter.TextSplitter

  @separators ["\n\n", "\n", " "]

  @doc """
  Recursively splits text by different characters.
  Each line is merged with the previous according to the chunk & overlap length.
  """
  def split(text, chunk_size, overlap \\ 0) do
    {separator, splits} = split_text(text, %{chunk_size: chunk_size, overlap: overlap})

    splits
    |> merge(chunk_size, overlap, separator)
  end

  defp split_text(text, opts) do
    separator = Enum.find(@separators, nil, fn s -> String.contains?(text, s) end)

    # no separator means the text is an entire word
    if separator do
      splits =
        String.split(text, separator)
        |> _split_text([], opts)
        |> merge(opts[:chunk_size], 0, separator)

      {separator, splits}
    else
      {" ", [text]}
    end
  end

  defp _split_text([], splits, _opts) do
    splits
  end

  defp _split_text([head | tail], splits, %{chunk_size: chunk_size} = opts) do
    if String.length(head) <= chunk_size do
      splits = Enum.concat(splits, [head])
      _split_text(tail, splits, opts)
    else
      {_, inner_splits} = split_text(head, opts)

      splits = Enum.concat(splits, inner_splits)

      _split_text(tail, splits, opts)
    end
  end
end
