defmodule Train.Functions.ZeroShotReact.PromptBuilder do
  alias Train.LlmChain
  alias Train.OpenAI

  @spec build(LlmChain.t(), String.t(), String.t()) :: list(OpenAI.message())
  def build(
        question,
        intermediate_steps,
        prompt
      ) do
    Enum.concat(
      [
        %{role: "system", content: prompt},
        %{role: "user", content: question}
      ],
      intermediate_steps |> Enum.reverse()
    )
  end
end
