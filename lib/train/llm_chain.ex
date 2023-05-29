defmodule Train.LlmChain do
  alias Train.ToolSpec
  alias Train.Clients.OpenAIConfig
  alias Train.PromptSpec
  alias Train.Agents.ConversationalChatPrompts

  defstruct max_iterations: 5,
            memory_pid: nil,
            openai_config: OpenAIConfig.new(),
            log_level: :info,
            tools: [],
            prompts: ConversationalChatPrompts

  @type t :: %__MODULE__{
          max_iterations: integer(),
          memory_pid: pid(),
          openai_config: OpenAIConfig.t(),
          log_level: atom(),
          tools: list(ToolSpec.t()),
          prompts: PromptSpec.t()
        }

  @doc """
  Creates new config with the given attributes.
  """
  def new(attrs \\ %{}) do
    config = %__MODULE__{}
    Map.merge(config, attrs)
  end
end
