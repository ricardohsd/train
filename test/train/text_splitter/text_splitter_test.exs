defmodule Train.TextSplitter.TextSplitterText do
  use ExUnit.Case, async: true

  import Train.TextSplitter.TextSplitter

  test "merge string with 0 overlap" do
    input = [
      "Hi",
      "John.",
      "What's",
      "your",
      "name?"
    ]

    output = merge(input, 10, 0)

    expected_output = ["Hi John.", "What's", "your name?"]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 10)
  end

  test "merge string list with overlap of 2 chars" do
    input = [
      "Hi",
      "my",
      "name",
      "is",
      "john.",
      "What's",
      "your",
      "name?"
    ]

    output = merge(input, 10, 3)

    expected_output = [
      "Hi my name",
      "me is john.",
      "n. What's",
      "'s your name?"
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 13)
  end

  test "merge in chunks of min 20 chars with 0 overlap" do
    input = [
      "Hello John",
      "It was nice to speak",
      "with you yesterday!",
      "I hope this message",
      "isn't weird, right,",
      "ha ha ha ha ha.",
      "Hope you are well.",
      "Byeeeeeeeeeee! s2"
    ]

    output = merge(input, 20, 0)

    expected_output = [
      "Hello John It was",
      "nice to speak with",
      "you yesterday! I",
      "hope this message",
      "isn't weird, right,",
      "ha ha ha ha ha. Hope",
      "you are well.",
      "Byeeeeeeeeeee! s2"
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 20)
  end

  test "ensure hard limit on large strings" do
    input = [
      "Hello John",
      "It was nice to speak",
      "with you.",
      "I hope this message",
      "isn't weird, right,",
      "ha ha ha ha ha.",
      "Hope you are well.",
      "Byeeeeeeeeeee! s2"
    ]

    output = split_by_chunk(input, 10)

    expected_output = [
      "Hello John",
      "It was ni",
      "ce to spea",
      "k with you",
      ". I hope t",
      "his messag",
      "e isn't we",
      "ird, right",
      ", ha ha ha",
      "ha ha. Ho",
      "pe you are",
      "well. Bye",
      "eeeeeeeeee",
      "! s2"
    ]

    assert output == expected_output
  end

  test "ensure soft limit on large strings" do
    input = [
      "Hello John",
      "It was nice to speak",
      "with you.",
      "I hope this message",
      "isn't weird, right,",
      "ha ha ha ha ha.",
      "Hope you are well.",
      "Byeeeeeeeeeee! s2"
    ]

    output = ensure_soft_limit(input, 10)

    expected_output = [
      "Hello John",
      "It was",
      "nice to",
      "speak with",
      "you. I",
      "hope this",
      "message",
      "isn't",
      "weird,",
      "right, ha",
      "ha ha ha",
      "ha. Hope",
      "you are",
      "well.",
      "Byeeeeeeee",
      "eee! s2"
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 10)
  end

  test "ensure soft limit splits large strings" do
    input = [
      "123456789ABCDEFGHIJLM",
      "XYZ",
      "123456789ABCDEFGHIJLM",
      "983"
    ]

    output = ensure_soft_limit(input, 10)

    expected_output = [
      "123456789A",
      "BCDEFGHIJL",
      "M XYZ",
      "123456789A",
      "BCDEFGHIJL",
      "M 983"
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 10)
  end

  test "ensure soft limit with small strings" do
    input = [
      "Hi",
      "my",
      "name",
      "is",
      "john.",
      "What's",
      "your",
      "name?"
    ]

    output = ensure_soft_limit(input, 10)

    expected_output = ["Hi my name", "is john.", "What's", "your name?"]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 10)
  end

  def assert_strings_with_max_length(list, length) do
    for l <- list do
      assert String.length(l) <= length,
             "text: #{inspect(l)} (#{String.length(l)}) length doesn't match #{length}"
    end
  end
end
