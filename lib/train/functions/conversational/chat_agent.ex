defmodule Train.Functions.Conversational.ChatAgent do
  import Train.LevelLogger

  alias Train.Clients.OpenAI
  alias Train.Functions
  alias Train.LlmChain
  alias Train.Functions.Conversational.PromptBuilder

  @doc """
  Uses the given chain and memory to ask questions. It uses OpenAI's function calling.

  Usage:
    alias Train.Functions.Conversational.ChatAgent
    {:ok, memory_pid} = Train.Memory.BufferTokenWindowAgent.start_link()
    tools = [Train.Tools.SerpApi, Train.Tools.BasicCalculator]
    chain = Train.LlmChain.new(%{memory: {memory_pid, Train.Memory.BufferAgent}, functions: tools})
    {:ok, response} = chain |> ChatAgent.run("Who is Angela Merkel?")
    {:ok, response} = chain |> ChatAgent.run("Where was she born?")
  """
  @spec run(LlmChain.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def run(
        %LlmChain{
          memory: {memory_pid, memory},
          functions: _
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
    intermediate_steps = []

    with {:ok, response} <-
           take_next_steps("", question, intermediate_steps, chat_history, chain) do
      messages = [
        %{role: "user", content: question},
        %{role: "assistant", content: response}
      ]

      {:ok, messages, response}
    else
      {:error, messages, err} -> {:error, messages, err}
    end
  end

  defp take_next_steps(tool_result, _question, _intermediate_steps, _chat_history, %LlmChain{
         max_iterations: 0
       }) do
    {:ok, tool_result}
  end

  defp take_next_steps(
         _,
         question,
         intermediate_steps,
         chat_history,
         %LlmChain{max_iterations: iteration, functions: tools, openai_config: openai_config} =
           chain
       ) do
    with messages <- PromptBuilder.build(question, intermediate_steps, chat_history, chain),
         functions <- Functions.format_tools(tools),
         {:ok, response} <- OpenAI.chat(messages, functions, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages, pretty: true)}", chain)
      log("\nIt: #{iteration}, LLm response: #{inspect(response, pretty: true)}", chain)

      process(response, question, intermediate_steps, chat_history, chain)
    else
      err -> err
    end
  end

  defp process(
         %{
           "choices" => [
             %{
               "finish_reason" => "function_call",
               "message" => %{
                 "role" => "assistant",
                 "function_call" => %{"arguments" => arguments, "name" => name} = function_call
               }
             }
             | _tail
           ]
         },
         question,
         intermediate_steps,
         chat_history,
         %LlmChain{functions: tools, max_iterations: iteration} = chain
       ) do
    args = Jason.decode!(arguments)
    {:ok, tool_result} = Functions.get_tool(tools, name).query(args["query"], chain)

    log("\nIt: #{iteration}, Tool response: #{inspect(tool_result)}", chain)

    assistant = %{role: "assistant", content: nil, function_call: function_call}
    function = %{role: "function", name: name, content: "#{tool_result}"}

    intermediate_steps = [function | [assistant | intermediate_steps]]
    log("\nIt: #{iteration}, Intermediate steps: #{inspect(intermediate_steps, pretty: true)}", chain)

    take_next_steps(tool_result, question, intermediate_steps, chat_history, %{
      chain
      | max_iterations: iteration - 1
    })
  end

  defp process(
         %{
           "choices" => [
             %{
               "finish_reason" => "stop",
               "message" => %{"role" => "assistant", "content" => result}
             }
             | _tail
           ]
         },
         _question,
         _intermediate_steps,
         _chat_history,
         _chain
       ) do
    {:ok, result}
  end

  defp validate_chain(%LlmChain{
         openai_config: openai_config,
         memory: {memory_pid, memory},
         functions: tools,
         max_iterations: max_iterations
       }) do
    cond do
      length(tools) == 0 -> {:error, "functions can't be empty"}
      memory_pid == nil -> {:error, "memory agent pid can't be null"}
      memory == nil -> {:error, "memory agent type can't be null"}
      openai_config == nil -> {:error, "OpenAI config can't be null"}
      max_iterations <= 0 -> {:error, "max_iterations must be higher than 0"}
      true -> :ok
    end
  end
end
