defmodule Train.Agents.ConversationalChatAgent do
  require Logger

  import Train.Utilities.Format
  import Train.Tools

  alias Train.Clients.OpenAI
  alias Train.ToolSpec
  alias Train.Agents.OutputParser
  alias Train.PromptBuilder
  alias Train.LlmChain

  @doc """
  Calls the agent with the given question and tools.
  It returns :ok, the list of messages used in the OpenAI's api, and the response.

  A previous conversation can be passed as the 3rd parameter (messages).
  """
  @spec call(LlmChain.t(), String.t(), String.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def call(%LlmChain{tools: tools} = chain, question, chat_history \\ []) do
    prompt = create_prompt(chain, question, tools, chat_history) |> PromptBuilder.build()

    messages = [
      %{role: "system", content: prompt}
    ]

    with {messages, response} <- take_next_steps(messages, "", chain) do
      {:ok, messages, response}
    else
      {:error, messages, ""} -> {:error, messages, ""}
    end
  end

  defp take_next_steps(messages, tool_result, %LlmChain{max_iterations: 0}) do
    {messages, tool_result}
  end

  defp take_next_steps(
         messages,
         _,
         %LlmChain{tools: tools, max_iterations: iteration, openai_config: openai_config} = chain
       ) do
    with {:ok, messages, choice} <- OpenAI.generate(:messages, messages, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages)}\n\n", chain)
      log("\nIt: #{iteration}, Choice: #{inspect(choice)}", chain)

      action = choice |> OutputParser.parse()
      log("\nIt: #{iteration}, Action: #{inspect(action)}", chain)

      tool_result = run_action(action, tools)
      log("\nIt: #{iteration}, Tool result: #{inspect(tool_result)}", chain)

      # TODO: Should the LLM's action be added to the buffer?
      # messages = Enum.concat(messages, [%{role: "assistant", content: choice}])
      messages = Enum.concat(messages, [%{role: "assistant", content: "#{tool_result}"}])

      if action["action"] == "Final Answer" do
        {messages, tool_result}
      else
        take_next_steps(messages, tool_result, %{chain | max_iterations: iteration - 1})
      end
    else
      {:error, %HTTPoison.Error{reason: :timeout, id: nil}} ->
        {:error, messages, ""}
    end
  end

  @doc """
  Creates the system prompt for the agent.
  """
  @spec create_prompt(
          LlmChain.t(),
          String.t(),
          list(ToolSpec.t()),
          list(String.t())
        ) :: list(String.t())
  def create_prompt(
        %LlmChain{system_prompt: system_prompt, human_prompt: human_prompt},
        input,
        tools,
        chat_history \\ []
      ) do
    final_prompt = human_prompt(human_prompt.to_s(), tools) |> format(:input, input)
    history = chat_history |> Enum.join("\n") |> String.trim()

    [
      {:system, system_prompt.to_s()},
      {:chat_history, history},
      {:human, final_prompt}
    ]
  end

  defp human_prompt(prompt, tools) do
    prompt
    |> format(:format_instructions, OutputParser.format_instructions())
    |> format(:tool_names, tool_names(tools))
    |> format(:tools, tool_descriptions(tools))
  end

  defp log(message, %LlmChain{log_level: log_level}) do
    Logger.log(log_level, message)
  end
end
