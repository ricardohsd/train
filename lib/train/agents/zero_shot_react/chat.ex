defmodule Train.Agents.ZeroShotReact.Chat do
  import Train.LevelLogger

  alias Train.Clients.OpenAI
  alias Train.Agents.ZeroShotReact.OutputParser
  alias Train.LlmChain
  alias Train.Agents.ZeroShotReact.PromptBuilder

  @doc """
  This agents follows the ReAct model to determine which tool can be used.
  It doesn't use previous conversations, for that please check the Conversational.ChatAgent.

  It returns :ok, the list of messages used in the OpenAI's api, and the response.
  """
  @spec call(LlmChain.t(), String.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def call(%LlmChain{tools: _} = chain, question) do
    intermediate_steps = []

    with {_messages, response} <-
           take_next_steps([], "", question, intermediate_steps, chain) do
      messages = [
        %{role: "user", content: question},
        %{role: "assistant", content: response}
      ]

      {:ok, messages, response}
    else
      {:error, messages, err} -> {:error, messages, err}
    end
  end

  defp take_next_steps(messages, tool_result, _question, _intermediate_steps, %LlmChain{
         max_iterations: 0
       }) do
    {messages, tool_result}
  end

  defp take_next_steps(
         _messages,
         _,
         question,
         intermediate_steps,
         %LlmChain{max_iterations: iteration, openai_config: openai_config} = chain
       ) do
    with messages <- PromptBuilder.build(chain, question, intermediate_steps),
         {:ok, messages, choice} <- OpenAI.generate(messages, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages, pretty: true)}\n\n", chain)
      log("\nIt: #{iteration}, LLm response: #{inspect(choice, pretty: true)}", chain)

      {action, tool_result, intermediate_steps} =
        choice
        |> OutputParser.parse()
        |> process_actions(intermediate_steps, nil, nil, chain)

      log("\nIt: #{iteration}, Steps: #{inspect(intermediate_steps, pretty: true)}", chain)

      if action["action"] == "Final Answer" do
        {messages, tool_result}
      else
        take_next_steps(messages, tool_result, question, intermediate_steps, %{
          chain
          | max_iterations: iteration - 1
        })
      end
    else
      err -> err
    end
  end

  def process_actions([], intermediate_steps, last_action, tool_result, _) do
    {last_action, tool_result, intermediate_steps}
  end

  def process_actions([action | tail], intermediate_steps, _last_action, _tool_result, chain) do
    {action, tool_result, intermediate_steps} = process_action(action, intermediate_steps, chain)
    process_actions(tail, intermediate_steps, action, tool_result, chain)
  end

  def process_action({thought, action}, intermediate_steps, %LlmChain{tools: _} = chain) do
    {:ok, tool_result} = Train.Tools.run_action(action, chain)

    observation = tool_result
    intermediate_steps = [{:thought, thought} | intermediate_steps]
    intermediate_steps = [{:action, action} | intermediate_steps]
    intermediate_steps = [{:observation, observation} | intermediate_steps]

    {action, tool_result, intermediate_steps}
  end
end
