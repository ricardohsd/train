defmodule Train.Agents.Conversational.ChatAgent do
  import Train.Tools
  import Train.LevelLogger

  alias Train.Clients.OpenAI
  alias Train.Agents.Conversational.OutputParser
  alias Train.LlmChain
  alias Train.Agents.Conversational.PromptBuilder

  @doc """
  Calls the agent with the given question and tools.
  It returns :ok, the list of messages used in the OpenAI's api, and the response.

  A previous conversation can be passed as the 3rd parameter (messages).
  """
  @spec call(LlmChain.t(), String.t(), list(String.t())) ::
          {:error, list(OpenAI.message()), String.t()} | {:ok, list(OpenAI.message()), String.t()}
  def call(
        chain,
        question,
        chat_history \\ []
      ) do
    with {_intermediate_steps, response} <- take_next_steps(chat_history, {}, question, "", chain) do
      {
        :ok,
        [%{role: "user", content: question}, %{role: "assistant", content: response}],
        response
      }
    else
      err -> err
    end
  end

  defp take_next_steps(_chat_history, intermediate_steps, _question, tool_result, %LlmChain{
         max_iterations: 0
       }) do
    {intermediate_steps, tool_result}
  end

  defp take_next_steps(
         chat_history,
         intermediate_steps,
         question,
         _tool_result,
         %LlmChain{max_iterations: iteration, openai_config: openai_config} = chain
       ) do
    with messages <- PromptBuilder.build(chain, question, chat_history, intermediate_steps),
         {:ok, _, choice} <- OpenAI.generate(:messages, messages, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages)}", chain)
      log("\nIt: #{iteration}, LLM response: #{inspect(choice)}", chain)

      action = choice |> OutputParser.parse()
      log("\nIt: #{iteration}, Parsed action: #{inspect(action)}", chain)

      {:ok, tool_result} = run_action(action, chain)
      log("\nIt: #{iteration}, Tool result: #{inspect(tool_result)}", chain)

      intermediate_steps = {choice, tool_result}

      if action["action"] == "Final Answer" do
        {intermediate_steps, tool_result}
      else
        take_next_steps(chat_history, intermediate_steps, question, tool_result, %{
          chain
          | max_iterations: iteration - 1
        })
      end
    else
      {:error, _messages, err} -> {:error, intermediate_steps, err}
    end
  end
end
