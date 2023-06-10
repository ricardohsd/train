defmodule Train.Chains.ConversationChain do
  require Logger

  alias Train.Agents.Conversational.ChatAgent
  alias Train.LlmChain

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
    {:ok, response} = chain |> Train.Chains.ConversationChain.run("Who is Angela Merkel?")
    {:ok, response} = chain |> Train.Chains.ConversationChain.run("Where was she born?")
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
           ChatAgent.call(
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
