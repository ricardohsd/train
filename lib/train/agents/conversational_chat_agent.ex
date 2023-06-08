defmodule Train.Agents.ConversationalChatAgent do
  import Train.Utilities.Format
  import Train.Tools
  import Train.LevelLogger

  alias Train.Clients.OpenAI
  alias Train.Tools
  alias Train.Agents.OutputParser
  alias Train.PromptBuilder
  alias Train.LlmChain

  @doc """
  Calls the agent with the given question and tools.
  It returns :ok, the list of messages used in the OpenAI's api, and the response.

  A previous conversation can be passed as the 3rd parameter (messages).
  """
  @spec call(LlmChain.t(), String.t(), list(String.t())) ::
          {:error, list(OpenAI.message()), String.t()} | {:ok, list(OpenAI.message()), String.t()}
  def call(%LlmChain{tools: tools} = chain, question, chat_history \\ []) do
    prompt = create_prompt(chain, question, tools, chat_history) |> PromptBuilder.build()

    messages = [
      %{role: "system", content: prompt}
    ]

    with {messages, response} <- take_next_steps(messages, "", question, chain) do
      messages = messages |> Enum.reverse()
      {:ok, messages, response}
    else
      err -> err
    end
  end

  defp take_next_steps(messages, tool_result, _, %LlmChain{max_iterations: 0}) do
    {messages, tool_result}
  end

  defp take_next_steps(
         messages,
         _,
         question,
         %LlmChain{max_iterations: iteration, openai_config: openai_config} = chain
       ) do
    with {:ok, messages, choice} <- OpenAI.generate(:messages, messages, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages)}", chain)
      log("\nIt: #{iteration}, Choice: #{inspect(choice)}", chain)

      action = choice |> OutputParser.parse()
      log("\nIt: #{iteration}, Action: #{inspect(action)}", chain)

      {:ok, tool_result} = run_action(action, chain)
      log("\nIt: #{iteration}, Tool result: #{inspect(tool_result)}", chain)

      messages =
        prepend(
          messages,
          %{role: "user", content: question},
          %{role: "assistant", content: "#{tool_result}"}
        )

      if action["action"] == "Final Answer" do
        {messages, tool_result}
      else
        take_next_steps(messages, tool_result, question, %{chain | max_iterations: iteration - 1})
      end
    else
      {:error, _messages, err} -> {:error, messages, err}
    end
  end

  # The agent can step multiple times with the same question and give the same output
  # in that case the messages shouldn't be duplicated.
  defp prepend(messages, user, assistant) do
    # Revert to be able to ignore the system prompt
    [%{content: _, role: "system"} | tail] = messages |> Enum.reverse()

    chunks = tail |> Enum.chunk_every(2)
    has_messages = Enum.any?(chunks, fn [u, a] -> u == user && a == assistant end)

    if has_messages do
      messages
    else
      [assistant | [user | messages]]
    end
  end

  @doc """
  Creates the system prompt for the agent.
  """
  @spec create_prompt(
          LlmChain.t(),
          String.t(),
          list(Tools.tool_wrapper()),
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
end
