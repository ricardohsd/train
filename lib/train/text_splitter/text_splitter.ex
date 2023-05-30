defmodule Train.TextSplitter.TextSplitter do
  @doc """
  Merges the lines with chunks of max X chars.
  It can also overlap with the previous entry.

  The final size of each line is the chunk + overlap.
  """
  def merge(lines, chunk \\ 100, overlap \\ 0, separator \\ " ") do
    separator = if String.length(separator) == 0, do: "", else: " "

    {lines, _} =
      lines
      # add an empty line as a hack to force processing the last line
      |> Enum.concat([separator])
      |> ensure_soft_limit(chunk)
      |> Enum.filter(fn s -> String.length(s) != 0 end)
      |> Enum.reduce({[], ""}, fn entry, {list, prev} ->
        prev =
          String.split(prev, separator)
          |> Enum.take(-1)
          |> Enum.join(separator)
          |> String.trim()

        # Calculates the pos to split the last N chars,
        # where N takes into account the overlap and an empty space.
        pos = String.length(prev) - overlap + 1
        prev = String.slice(prev, pos..-1)

        text = (prev <> separator <> entry) |> String.trim()

        {[text | list], entry}
      end)

    lines
    |> Enum.reverse()
  end

  @doc """
  Ensure list of strings are redistributed into strings that are within the chunk size.
  It splits words to reach the chunk size.
  """
  def ensure_hard_limit(lines, chunk) do
    lines
    |> Enum.join(" ")
    |> String.codepoints()
    |> Enum.chunk_every(chunk)
    |> Enum.map(&Enum.join/1)
    |> Enum.map(&String.trim/1)
  end

  def split_by_chunk(list, size) when is_list(list) do
    list |> Enum.join(" ") |> split_by_chunk(size)
  end

  def split_by_chunk(string, size), do: split_by_chunk(string, size, [])

  defp split_by_chunk(<<>>, _size, acc), do: Enum.reverse(acc)

  defp split_by_chunk(string, size, acc) when byte_size(string) > size do
    <<c::size(size)-binary, rest::binary>> = string
    c = String.trim(c)
    split_by_chunk(rest, size, [c | acc])
  end

  defp split_by_chunk(leftover, size, acc) do
    split_by_chunk(<<>>, size, [leftover | acc])
  end

  @doc """
  Ensure list of strings are redistributed into strings that are within the chunk size.
  It won't break words, and will try to fit them if there is space.
  """
  def ensure_soft_limit(lines, chunk) do
    separator = " "

    lines
    |> Enum.join(separator)
    |> String.split(separator)
    |> chunk_words(chunk)
    |> Enum.map(fn entry -> Enum.join(entry, " ") end)
    |> Enum.map(&String.trim/1)
  end

  defp chunk_words(enum, chunk) do
    {list, acc} =
      Enum.reduce(enum, {[], []}, fn entry, {list, acc} ->
        text = [entry | acc] |> Enum.join(" ")

        cond do
          String.length(text) <= chunk ->
            {list, [entry | acc]}

          String.length(entry) > chunk ->
            # If there is a word that happens to be bigger than the chunk it splits
            # the word in chars and calculate if it can be joined with previous chunk.
            [last | chunks] = split_long_word(entry, chunk)
            result = Enum.concat(chunks, [acc | list]) |> Enum.filter(fn e -> length(e) > 0 end)
            {result, last}

          true ->
            {[acc | list], [entry]}
        end
      end)

    [acc | list]
    |> Enum.filter(fn e -> length(e) > 0 end)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
  end

  defp split_long_word(word, chunk) do
    word
    |> String.codepoints()
    |> Enum.chunk_every(chunk)
    |> Enum.map(&Enum.join/1)
    |> Enum.map(fn e -> [String.trim(e)] end)
    |> Enum.reverse()
  end
end
