defmodule Train.LlmChain do
  alias Train.Tools
  alias Train.Clients.OpenAIConfig
  alias Train.Clients.PineconeConfig
  alias Train.PromptSpec
  alias Train.Memory.MemorySpec
  alias Train.Agents.ConversationalChatPrompts

  defstruct max_iterations: 5,
            memory: nil,
            openai_config: OpenAIConfig.new(),
            pinecone_config: PineconeConfig.new(),
            log_level: :info,
            tools: [],
            system_prompt: ConversationalChatPrompts.SystemPrompt,
            human_prompt: ConversationalChatPrompts.HumanPrompt

  @type t :: %__MODULE__{
          max_iterations: integer(),
          memory: {pid(), MemorySpec.t()},
          openai_config: OpenAIConfig.t(),
          pinecone_config: PineconeConfig.t(),
          log_level: atom(),
          tools: list(Tools.tool_wrapper()),
          system_prompt: PromptSpec.t(),
          human_prompt: PromptSpec.t()
        }

  @doc """
  Creates new config with the given attributes.
  """
  def new(attrs \\ %{}) do
    config = %__MODULE__{}
    Map.merge(config, attrs)
  end
end
