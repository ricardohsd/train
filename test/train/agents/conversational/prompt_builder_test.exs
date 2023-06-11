defmodule Train.Agents.Conversational.PromptBuilderTest do
  use ExUnit.Case, async: true

  alias Train.Agents.Conversational.PromptBuilder

  setup_all do
    Logger.configure(level: :warning)
    HTTPoison.start()

    tools = [
      %{
        name: "Calculator",
        description: "Calculate matematical questions, like age of a person, distance, etc",
        func: Train.Tools.BasicCalculator
      }
    ]

    chain =
      Train.LlmChain.new(%{
        memory: nil,
        tools: tools
      })

    %{chain: chain}
  end

  test "create messages", %{chain: chain} do
    chat_history = [
      %{role: "user", content: "Who is Angela Merkel?"},
      %{role: "assistant", content: "Angela Merkel is a German former politician."}
    ]

    intermediate_steps =
      {"```json\n{\n  \"action\": \"Calculator\",\n  \"action_input\": \"2022 - 1954\"\n}\n```",
       "68"}

    messages = PromptBuilder.build(chain, "How old is she?", chat_history, intermediate_steps)

    assert messages == [
             %{
               content:
                 "Assistant is a large language model trained by OpenAI.\n\nAssistant is designed to be able to assist with a wide range of tasks, from answering simple questions to providing in-depth explanations and discussions on a wide range of topics. As a language model, Assistant is able to generate human-like text based on the input it receives, allowing it to engage in natural-sounding conversations and provide responses that are coherent and relevant to the topic at hand.\n\nAssistant is constantly learning and improving, and its capabilities are constantly evolving. It is able to process and understand large amounts of text, and can use this knowledge to provide accurate and informative responses to a wide range of questions. Additionally, Assistant is able to generate its own text based on the input it receives, allowing it to engage in discussions and provide explanations and descriptions on a wide range of topics.\n\nOverall, Assistant is a powerful system that can help with a wide range of tasks and provide valuable insights and information on a wide range of topics. Whether you need help with a specific question or just want to have a conversation about a particular topic, Assistant is here to assist.",
               role: "system"
             },
             %{content: "Who is Angela Merkel?", role: "user"},
             %{content: "Angela Merkel is a German former politician.", role: "assistant"},
             %{
               content:
                 "TOOLS\n------\nAssistant can ask the user to use tools to look up information that may be helpful in answering the users original question. The tools the human can use are:\n\n> Calculator Calculate matematical questions, like age of a person, distance, etc\n\nRESPONSE FORMAT INSTRUCTIONS\n----------------------------\n\nWhen responding to me, please output a response in one of two formats:\n\n**Option 1:**\nUse this if you want the human to use a tool.\nMarkdown code snippet formatted in the following schema:\n\n```json\n{\n  \"action\": string \\ The action to take. Must be one of Calculator\n  \"action_input\": string \\ The input to the action\n}\n```\n\n**Option #2:**\nUse this if you want to respond directly to the human. Markdown code snippet formatted in the following schema:\n\n```json\n{\n  \"action\": \"Final Answer\",\n  \"action_input\": string \\ You should put what you want to return to use here\n}\n```\n\nUSER'S INPUT\n--------------------\nHere is the user's input (remember to respond with a markdown code snippet of a json blob with a single action, and NOTHING else):\n\nHow old is she?",
               role: "user"
             },
             %{
               content:
                 "```json\n{\n  \"action\": \"Calculator\",\n  \"action_input\": \"2022 - 1954\"\n}\n```",
               role: "assistant"
             },
             %{
               content:
                 "TOOL RESPONSE:\n---------------------\n68\n\nUSER'S INPUT\n--------------------\n\nOkay, so what is the response to my last comment? If using information obtained from the tools you must mention it explicitly without mentioning the tool names - I have forgotten all TOOL RESPONSES! Remember to respond with a markdown code snippet of a json blob with a single action, and NOTHING else.",
               role: "user"
             }
           ]
  end
end
