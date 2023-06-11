defmodule Train.Agents.Conversational.PromptBuilder do
  import Train.Utilities.Format
  import Train.Tools

  alias Train.LlmChain
  alias Train.Agents.Conversational.OutputParser

  def build(
        %LlmChain{
          tools: tools,
          prompt_template: prompt_template
        },
        question,
        chat_history,
        intermediate_steps
      ) do
    human = human_prompt(prompt_template.for(:human), question, tools)

    messages = [%{role: "system", content: prompt_template.for(:system)}]
    messages = Enum.concat(chat_history |> Enum.reverse(), messages)
    messages = [%{role: "user", content: human} | messages]
    messages = Enum.concat(scratchpad(intermediate_steps, prompt_template), messages)
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

  defp scratchpad({action, observation}, prompt_template) do
    user = prompt_template.for(:scratchpad) |> format(:observation, "#{observation}")

    [
      %{role: "user", content: user},
      %{role: "assistant", content: action}
    ]
  end
end
