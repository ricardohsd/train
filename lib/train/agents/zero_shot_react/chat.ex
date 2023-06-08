defmodule Train.Agents.ZeroShotReact.Chat do
  import Train.Agents.ZeroShotReact.Prompt
  import Train.Utilities.Format
  import Train.Tools
  import Train.LevelLogger

  alias Train.Clients.OpenAI
  alias Train.Tools
  alias Train.Agents.ZeroShotReact.OutputParser
  alias Train.PromptBuilder
  alias Train.LlmChain

  @doc """
  This agents follows the ReAct model to determine which tool can be used.
  It doesn't use previous conversations, for that please check the ConversationalChatAgent.

  It returns :ok, the list of messages used in the OpenAI's api, and the response.
  """
  @spec call(LlmChain.t(), String.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def call(%LlmChain{tools: tools} = chain, question) do
    system = system_prompt(tools) |> PromptBuilder.build()
    intermediate_steps = []

    with {messages, response} <-
           take_next_steps([], "", system, question, intermediate_steps, chain) do
      {:ok, messages, response}
    else
      {:error, messages, err} -> {:error, messages, err}
    end
  end

  defp take_next_steps(messages, tool_result, _system, _question, _intermediate_steps, %LlmChain{
         max_iterations: 0
       }) do
    {messages, tool_result}
  end

  defp take_next_steps(
         _messages,
         _,
         system,
         question,
         intermediate_steps,
         %LlmChain{max_iterations: iteration, openai_config: openai_config} = chain
       ) do
    human =
      "{input}\n\n{scratchpad}"
      |> format(:input, question)
      |> format(:scratchpad, scratchpad(intermediate_steps, question))

    messages = [
      %{role: "system", content: system},
      %{role: "user", content: human}
    ]

    with {:ok, messages, choice} <- OpenAI.generate(:messages, messages, openai_config) do
      log("\nIt: #{iteration}, Messages: #{inspect(messages)}\n\n", chain)
      log("\nIt: #{iteration}, LLm response: #{inspect(choice)}", chain)

      {action, tool_result, intermediate_steps} =
        choice
        |> OutputParser.parse()
        |> process_actions(intermediate_steps, nil, nil, chain)

      log("\nIt: #{iteration}, Steps: #{inspect(intermediate_steps)}", chain)

      if action["action"] == "Final Answer" do
        {messages, tool_result}
      else
        take_next_steps(messages, tool_result, system, question, intermediate_steps, %{
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
    {:ok, tool_result} = run_action(action, chain)

    observation = tool_result
    intermediate_steps = [{:thought, thought} | intermediate_steps]
    intermediate_steps = [{:action, action} | intermediate_steps]
    intermediate_steps = [{:observation, observation} | intermediate_steps]

    {action, tool_result, intermediate_steps}
  end

  @doc """
  Creates the system prompt for the agent.
  """
  @spec system_prompt(list(Tools.tool_wrapper())) :: list({atom(), String.t()})
  def system_prompt(tools) do
    system =
      [
        prefix(),
        tool_descriptions(tools),
        format_instructions(),
        suffix()
      ]
      |> Enum.join("\n\n")
      |> format(:tool_names, tool_names(tools))

    [
      {:system, system}
    ]
  end

  @doc """
  Constructs the scratchpad to give the AI enough context to continue its thought process.
  """
  @spec scratchpad(list({atom(), String.t()}), String.t()) :: String.t()
  def scratchpad([], _) do
    ""
  end

  def scratchpad(intermediate_steps, question) do
    intermediate_steps = intermediate_steps |> Enum.reverse()
    intermediate_steps = [{:question, question} | intermediate_steps]

    """
    This was your previous work (but I haven't seen any of it! I only see what you return as final answer):
    #{parse_steps(intermediate_steps)}\nThought:
    """
    |> String.trim()
  end

  defp parse_steps([]) do
    ""
  end

  defp parse_steps([head | tail]) do
    "#{parse_step(head)}\n\n#{parse_steps(tail)}"
  end

  defp parse_step({:question, t}) do
    "Question: #{t}"
  end

  defp parse_step({:thought, t}) do
    t = String.replace(t, "Thought: ", "")
    "Thought: #{t}"
  end

  defp parse_step({:observation, t}) do
    "Observation: #{t}"
  end

  defp parse_step({:action, action}) do
    {:ok, json} = Jason.encode(action)
    "Action: ```json#{json}```"
  end
end
