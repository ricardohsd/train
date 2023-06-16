defmodule Train.Agents.Conversational.ChatAgent do
  import Train.LevelLogger

  alias Train.Tools
  alias Train.Clients.OpenAI
  alias Train.Agents.Conversational.OutputParser
  alias Train.LlmChain
  alias Train.Agents.Conversational.PromptBuilder

  @doc """
  Calls the agent with the given question and tools.
  It returns :ok, the list of intermediate messages used in the OpenAI's api, and the response.

  A previous conversation can be passed as the 3rd parameter (chat_history).
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
         {:ok, _, raw_resp} <- OpenAI.generate(messages, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages, pretty: true)}", chain)
      log("\nIt: #{iteration}, LLM response: #{inspect(raw_resp, pretty: true)}", chain)

      action = raw_resp |> OutputParser.parse()
      log("\nIt: #{iteration}, Parsed action: #{inspect(action, pretty: true)}", chain)

      {:ok, tool_result} = Tools.run_action(action, chain)
      log("\nIt: #{iteration}, Tool result: #{inspect(tool_result, pretty: true)}", chain)

      intermediate_steps = {raw_resp, tool_result}

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
