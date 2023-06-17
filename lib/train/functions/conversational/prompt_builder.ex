defmodule Train.Functions.Conversational.PromptBuilder do
  alias Train.LlmChain

  @spec build(LlmChain.t(), list(OpenAI.message()), list(OpenAI.message()), LlmChain.t()) ::
          list(OpenAI.message())
  def build(
        question,
        intermediate_steps,
        chat_history,
        %LlmChain{
          prompt_template: prompt_template
        }
      ) do
    messages = [%{role: "system", content: prompt_template.for(:system)} | chat_history]
    messages = [%{role: "user", content: question} | messages |> Enum.reverse()]

    Enum.concat(
      messages |> Enum.reverse(),
      intermediate_steps |> Enum.reverse()
    )
  end
end
