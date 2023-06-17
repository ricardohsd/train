defmodule Train.Functions.Conversational.PromptBuilderTest do
  use ExUnit.Case, async: true

  alias Train.Functions.Conversational.PromptBuilder

  defmodule SimpleTemplate do
    @behaviour Train.Agents.PromptSpec

    @impl true
    def for(:system) do
      "You are a helpful AI assistant."
    end
  end

  setup do
    chain = Train.LlmChain.new(%{prompt_template: SimpleTemplate})

    %{chain: chain}
  end

  test "use the question, chat history and intermediate steps to build messages", %{chain: chain} do
    question = "How old is he?"

    intermediate_steps = [
      %{content: "65 years", name: "google_search", role: "function"},
      %{
        content: nil,
        function_call: %{
          "arguments" => "{\n  \"query\": \"Olaf Scholz age\"\n}",
          "name" => "google_search"
        },
        role: "assistant"
      }
    ]

    chat_history = [
      %{
        content: "Who is currently the chanceller of Germany in 2023?",
        role: "user"
      },
      %{
        content:
          "The current chancellor of Germany in 2023 is Olaf Scholz. He has been serving as the chancellor since December 8, 2021. Olaf Scholz is a member of the Social Democratic Party and previously served as the Vice Chancellor in the fourth Merkel cabinet and as the Federal Minister of Finance from 2018 to 2021.",
        role: "assistant"
      }
    ]

    prompt = PromptBuilder.build(question, intermediate_steps, chat_history, chain)

    assert prompt == [
             %{role: "system", content: "You are a helpful AI assistant."},
             %{
               content: "Who is currently the chanceller of Germany in 2023?",
               role: "user"
             },
             %{
               content:
                 "The current chancellor of Germany in 2023 is Olaf Scholz. He has been serving as the chancellor since December 8, 2021. Olaf Scholz is a member of the Social Democratic Party and previously served as the Vice Chancellor in the fourth Merkel cabinet and as the Federal Minister of Finance from 2018 to 2021.",
               role: "assistant"
             },
             %{
               content: "How old is he?",
               role: "user"
             },
             %{
               content: nil,
               function_call: %{
                 "arguments" => "{\n  \"query\": \"Olaf Scholz age\"\n}",
                 "name" => "google_search"
               },
               role: "assistant"
             },
             %{content: "65 years", name: "google_search", role: "function"}
           ]
  end
end
