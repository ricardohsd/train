defmodule Train.Agents.Conversational.ChatAgent do
  import Train.LevelLogger

  alias Train.Tools
  alias Train.OpenAI
  alias Train.Agents.Conversational.OutputParser
  alias Train.LlmChain
  alias Train.Agents.Conversational.PromptBuilder

  @doc """
  Ask a question to the given chain.

  Usage:
    {:ok, memory_pid} = Train.Memory.BufferAgent.start_link()
    tools = [
      %{
        name: "Calculator",
        description: "Calculate matematical questions, like age of a person, distance, etc",
        func: Train.Tools.BasicCalculator
      },
      %{
        name: "Google search",
        description:
          "Useful for when you need to answer questions about current events. You should ask targeted questions",
        func: Train.Tools.SerpApi
      }
    ]
    chain = Train.LlmChain.new(%{memory: {memory_pid, Train.Memory.BufferAgent}, tools: tools})
    {:ok, response} = chain |> Train.Agents.Conversational.ChatAgent.run("Who is Angela Merkel?")
    {:ok, response} = chain |> Train.Agents.Conversational.ChatAgent.run("Where was she born?")
  """
  @spec run(LlmChain.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def run(
        %LlmChain{
          memory: {memory_pid, memory}
        } = chain,
        question
      ) do
    with :ok <- validate_chain(chain),
         chat_history <- memory.get(memory_pid),
         {:ok, messages, response} <-
           call(
             chain,
             question,
             chat_history
           ),
         :ok <- memory.put_many(memory_pid, messages) do
      {:ok, response}
    else
      err -> err
    end
  end

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
      {:error, err} -> {:error, err}
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
         {:ok, _, raw_resp} <- OpenAI.chat(messages, openai_config) do
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

  defp validate_chain(%LlmChain{
         openai_config: openai_config,
         memory: {memory_pid, memory},
         tools: tools,
         max_iterations: max_iterations
       }) do
    cond do
      length(tools) == 0 -> {:error, "tools can't be empty"}
      memory_pid == nil -> {:error, "memory agent pid can't be null"}
      memory == nil -> {:error, "memory agent type can't be null"}
      openai_config == nil -> {:error, "OpenAI config can't be null"}
      max_iterations <= 0 -> {:error, "max_iterations must be higher than 0"}
      true -> :ok
    end
  end
end
