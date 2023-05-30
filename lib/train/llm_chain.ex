defmodule Train.LlmChain do
  alias Train.ToolSpec
  alias Train.Clients.OpenAIConfig
  alias Train.Clients.Pinecone
  alias Train.PromptSpec
  alias Train.Agents.ConversationalChatPrompts

  defstruct max_iterations: 5,
            memory_pid: nil,
            openai_config: OpenAIConfig.new(),
            pinecone_config: %Pinecone.Config{},
            log_level: :info,
            tools: [],
            system_prompt: ConversationalChatPrompts.SystemPrompt,
            human_prompt: ConversationalChatPrompts.HumanPrompt

  @type t :: %__MODULE__{
          max_iterations: integer(),
          memory_pid: pid(),
          openai_config: OpenAIConfig.t(),
          pinecone_config: Pinecone.Config.t(),
          log_level: atom(),
          tools: list(ToolSpec.t()),
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
