defmodule Train.Functions.ZeroShotReact.Chat do
  import Train.LevelLogger

  alias Train.OpenAI
  alias Train.LlmChain
  alias Train.Functions
  alias Train.Functions.ZeroShotReact.PromptBuilder

  @doc """
  This agents uses OpenAPI's functions to follow the ReAct model to determine which tool can be used.
  It doesn't use previous conversations, for that please check the Conversational.ChatAgent.

  It returns :ok, the list of messages used in the OpenAI's api, and the response.
  """
  @spec call(LlmChain.t(), String.t(), String.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def call(%LlmChain{functions: _} = chain, question, prompt \\ "You are a helpful AI assistant.") do
    intermediate_steps = []

    with {:ok, response} <-
           take_next_steps("", question, intermediate_steps, prompt, chain) do
      messages = [
        %{role: "user", content: question},
        %{role: "assistant", content: response}
      ]

      {:ok, messages, response}
    else
      {:error, messages, err} -> {:error, messages, err}
    end
  end

  defp take_next_steps(tool_result, _question, _intermediate_steps, _prompt, %LlmChain{
         max_iterations: 0
       }) do
    {:ok, tool_result}
  end

  defp take_next_steps(
         _,
         question,
         intermediate_steps,
         prompt,
         %LlmChain{max_iterations: iteration, functions: tools, openai_config: openai_config} =
           chain
       ) do
    with messages <- PromptBuilder.build(question, intermediate_steps, prompt),
         functions <- Functions.format_tools(tools),
         {:ok, response} <- OpenAI.chat(messages, functions, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages, pretty: true)}", chain)
      log("\nIt: #{iteration}, LLm response: #{inspect(response, pretty: true)}", chain)
      log("\nIt: #{iteration}, Steps: #{inspect(intermediate_steps, pretty: true)}", chain)

      process(response, question, intermediate_steps, prompt, chain)
    else
      {:error, err} -> {:error, err}
    end
  end

  defp process(
         %{
           "choices" => [
             %{
               "finish_reason" => finish_reason,
               "message" => %{
                 "function_call" => %{"arguments" => arguments} = function_call
               }
             }
             | _tail
           ]
         },
         question,
         intermediate_steps,
         prompt,
         %LlmChain{functions: tools, max_iterations: iteration} = chain
       )
       when finish_reason in ["function_call", "stop"] do
    args = Jason.decode!(arguments)

    tool = Functions.get_tool(tools, function_call["name"])
    function_call = Functions.format_function_call(tool, function_call)

    {:ok, tool_result} = tool.query(args["query"], chain)

    log("\nIt: #{iteration}, Tool response: #{inspect(tool_result)}", chain)

    assistant = %{role: "assistant", content: nil, function_call: function_call}
    function = %{role: "function", name: tool.name, content: "#{tool_result}"}

    intermediate_steps = [function | [assistant | intermediate_steps]]

    log(
      "\nIt: #{iteration}, Intermediate steps: #{inspect(intermediate_steps, pretty: true)}",
      chain
    )

    take_next_steps(tool_result, question, intermediate_steps, prompt, %{
      chain
      | max_iterations: iteration - 1
    })
  end

  defp process(
         %{
           "choices" => [
             %{
               "finish_reason" => "stop",
               "message" => %{"content" => result}
             }
             | _tail
           ]
         },
         _question,
         _intermediate_steps,
         _prompt,
         _chain
       ) do
    {:ok, result}
  end
end
