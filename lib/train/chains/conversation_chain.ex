defmodule Train.Chains.ConversationChain do
  require Logger

  alias Train.Memory.BufferAgent
  alias Train.Agents.ConversationalChatAgent
  alias Train.LlmChain

  @doc """
  Ask a question to the given chain.

  Usage:
    {:ok, memory_pid} = Train.Memory.BufferAgent.start_link()
    tools = [Train.Tools.BasicCalculator, Train.Tools.SerpApi]
    chain = Train.LlmChain.new(%{memory_pid: memory_pid, tools: tools})
    {:ok, response} = chain |> Train.Chains.ConversationChain.run("Who is Angela Merkel?")
    {:ok, response} = chain |> Train.Chains.ConversationChain.run("Where was she born?")
  """
  @spec run(LlmChain.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def run(
        %LlmChain{
          memory_pid: memory_pid
        } = chain,
        question
      ) do
    with :ok <- validate_chain(chain),
         chat_history <- BufferAgent.get(memory_pid),
         {:ok, messages, response} <-
           ConversationalChatAgent.call(
             chain,
             question,
             chat_history
           ),
         :ok <- BufferAgent.put_many(memory_pid, messages) do
      {:ok, response}
    else
      err -> err
    end
  end

  defp validate_chain(%LlmChain{
         openai_config: openai_config,
         memory_pid: memory_pid,
         tools: tools,
         max_iterations: max_iterations
       }) do
    cond do
      length(tools) == 0 -> {:error, "tools can't be empty"}
      memory_pid == nil -> {:error, "memory agent pid can't be null"}
      openai_config == nil -> {:error, "OpenAI config can't be null"}
      max_iterations <= 0 -> {:error, "max_iterations must be higher than 0"}
      true -> :ok
    end
  end
end
