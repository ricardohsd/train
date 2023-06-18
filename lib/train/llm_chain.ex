defmodule Train.LlmChain do
  alias Train.Tools
  alias Train.OpenAI
  alias Train.Clients.PineconeConfig
  alias Train.PromptSpec
  alias Train.Memory.MemorySpec
  alias Train.Agents.Conversational.Prompts

  defstruct max_iterations: 5,
            memory: nil,
            openai_config: OpenAI.Config.new(),
            pinecone_config: PineconeConfig.new(),
            log_level: :info,
            tools: [],
            functions: [],
            prompt_template: Prompts

  @type t :: %__MODULE__{
          max_iterations: integer(),
          memory: {pid(), MemorySpec.t()},
          openai_config: OpenAI.Config.t(),
          pinecone_config: PineconeConfig.t(),
          log_level: atom(),
          tools: list(Tools.tool_wrapper()),
          functions: list(Tools.Spec.t()),
          prompt_template: PromptSpec.t()
        }

  @doc """
  Creates new config with the given attributes.
  """
  def new(attrs \\ %{}) do
    config = %__MODULE__{}
    Map.merge(config, attrs)
  end
end
