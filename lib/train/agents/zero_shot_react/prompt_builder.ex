defmodule Train.Agents.ZeroShotReact.PromptBuilder do
  import Train.Utilities.Format
  import Train.Tools

  alias Train.Agents.ZeroShotReact.Prompts
  alias Train.LlmChain
  alias Train.Clients.OpenAI

  @spec build(LlmChain.t(), String.t(), list({atom(), String.t()})) :: list(OpenAI.message())
  def build(
        %LlmChain{
          tools: tools
        },
        question,
        intermediate_steps
      ) do
    system = system_prompt(tools)

    human =
      "{input}\n\n{scratchpad}"
      |> format(:input, question)
      |> format(:scratchpad, scratchpad(intermediate_steps, question))

    [
      %{role: "system", content: system},
      %{role: "user", content: human}
    ]
  end

  @doc """
  Creates the system prompt for the agent.
  """
  @spec system_prompt(list(Tools.tool_wrapper())) :: String.t()
  def system_prompt(tools) do
    [
      Prompts.prefix(),
      tool_descriptions(tools),
      Prompts.format_instructions(),
      Prompts.suffix()
    ]
    |> Enum.join("\n\n")
    |> format(:tool_names, tool_names(tools))
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

  def parse_steps([]) do
    ""
  end

  def parse_steps([head | tail]) do
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
