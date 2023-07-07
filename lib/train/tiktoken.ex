defmodule Train.Tiktoken do
  def count_tokens(nil) do
    0
  end

  def count_tokens(text) do
    {:ok, tokens} = ExTiktoken.CL100K.encode(text)
    length(tokens)
  end
end
