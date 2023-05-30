defmodule Train.TextSplitter.CharacterSplitterTest do
  use ExUnit.Case, async: true

  import Train.TextSplitter.CharacterSplitter

  test "split text in smaller chunks without overlap" do
    input = "foo bar baz a a"
    output = split_text(input, %{chunk_size: 3, separator: " "})
    expected = ["foo", "bar", "baz", "a a"]

    assert output == expected
  end

  test "split text in chunks without overlap" do
    input = "foo bar baz a a"
    output = split_text(input, %{chunk_size: 7, separator: " "})
    expected = ["foo bar", "baz a a"]

    assert output == expected
  end

  test "split text in chunks with basic char overlap" do
    input = "foo bar baz a a 123 c"
    output = split_text(input, %{chunk_size: 7, overlap: 2, separator: " "})
    expected = ["foo bar", "r baz a a", "a 123 c"]

    assert output == expected
  end
end
