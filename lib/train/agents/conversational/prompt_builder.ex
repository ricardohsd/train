defmodule Train.Agents.Conversational.PromptBuilder do
  import Train.Utilities.Format
  import Train.Tools

  alias Train.LlmChain
  alias Train.Agents.Conversational.OutputParser

  def build(
        %LlmChain{
          tools: tools,
          system_prompt: system_prompt,
          human_prompt: human_prompt,
          tool_response_prompt: tool_response_prompt
        },
        question,
        chat_history,
        intermediate_steps
      ) do
    human = human_prompt(human_prompt.to_s(), question, tools)

    messages = [%{role: "system", content: system_prompt.to_s()}]
    messages = Enum.concat(chat_history |> Enum.reverse(), messages)
    messages = [%{role: "user", content: human} | messages]
    messages = Enum.concat(scratchpad(intermediate_steps, tool_response_prompt), messages)
    messages = messages |> Enum.reverse()
    messages
  end

  defp human_prompt(prompt, question, tools) do
    prompt
    |> format(:format_instructions, OutputParser.format_instructions())
    |> format(:tool_names, tool_names(tools))
    |> format(:tools, tool_descriptions(tools))
    |> format(:input, question)
  end

  defp scratchpad({}, _) do
    []
  end

  defp scratchpad({action, observation}, tool_response_prompt) do
    user = tool_response_prompt.to_s() |> format(:observation, "#{observation}")

    [
      %{role: "user", content: user},
      %{role: "assistant", content: action}
    ]
  end
end
