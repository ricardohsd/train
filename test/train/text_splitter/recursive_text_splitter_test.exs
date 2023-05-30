defmodule Train.TextSplitter.RecursiveTextSplitterTest do
  use ExUnit.Case, async: true

  import Train.TextSplitter.RecursiveTextSplitter

  test "recursively split text" do
    text = """
    Hello John\nIt was nice to speak with you.\n\n
    I hope this message isn't weird, right, ha ha ha ha.
    Hope you are well. Byeeeeeeeeeee!\n\ns2
    """

    output = split(text, 10)

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
      "ha ha ha.",
      "Hope you",
      "are well.",
      "Byeeeeeeee",
      "eee! s2"
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 10)
  end

  test "recursively split text by chunks of 20" do
    text = """
    Hello John\nIt was nice to speak with you.\n\n
    I hope this message isn't weird, right, ha ha ha ha.
    Hope you are well. Byeeeeeeeeeee!\n\ns2
    """

    output = split(text, 20)

    expected_output = [
      "Hello John It was",
      "nice to speak with",
      "you. I hope this",
      "message isn't weird,",
      "right, ha ha ha ha.",
      "Hope you are well.",
      "Byeeeeeeeeeee! s2"
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 20)
  end

  test "recursively split a single line by chunks of 10" do
    text = "1234567890ABCDEFGHIJ"

    output = split(text, 10)

    expected_output = [
      "1234567890",
      "ABCDEFGHIJ"
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 10)
  end

  test "recursively split text by chunks of 10 without overlap" do
    text = "Hi.\n\nI'm Harrison.\n\nHow? Are? You?\nOkay then i a c d.
This is a weird text to write, but gotta test the splittingggg some how.

Bye!\n\n-H."

    output = split(text, 10, 0)

    expected_output = [
      "Hi. I'm",
      "Harrison.",
      "How? Are?",
      "You? Okay",
      "then i a c",
      "d. This is",
      "a weird",
      "text to",
      "write, but",
      "gotta test",
      "the",
      "splittingg",
      "gg some",
      "how. Bye!",
      "-H."
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 10)
  end

  test "recursively split text by chunks of 10 with overlap of 2" do
    text = "Hi.\n\nI'm Harrison.\n\nHow? Are? You?\nOkay then i a c d.
This is a weird text to write, but gotta test the splittinghjg some how.

Bye!\n\n-H."

    output = split(text, 10, 3)

    expected_output = [
      "Hi. I'm",
      "'m Harrison.",
      "n. How? Are?",
      "e? You? Okay",
      "ay then i a c",
      "c d. This is",
      "is a weird",
      "rd text to",
      "to write, but",
      "ut gotta test",
      "st the",
      "he splittingh",
      "gh jg some",
      "me how. Bye!",
      "e! -H."
    ]

    assert output == expected_output
    assert_strings_with_max_length(expected_output, 13)
  end

  def assert_strings_with_max_length(list, length) do
    for l <- list do
      assert String.length(l) <= length,
             "text: #{inspect(l)} (#{String.length(l)}) length doesn't match #{length}"
    end
  end
end
