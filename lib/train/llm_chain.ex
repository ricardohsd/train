defmodule Train.LlmChain do
  alias Train.Tools
  alias Train.OpenAI
  alias Train.Pinecone
  alias Train.Memory.MemorySpec
  alias Train.Agents.Conversational.Prompts

  defstruct max_iterations: 5,
            memory: nil,
            openai_config: OpenAI.Config.new(),
            pinecone_config: Pinecone.config(),
            log_level: :info,
            tools: [],
            functions: [],
            prompt_template: Prompts.new()

  @type t :: %__MODULE__{
          max_iterations: integer(),
          memory: {pid(), MemorySpec.t()},
          openai_config: OpenAI.Config.t(),
          pinecone_config: Pinecone.Config.t(),
          log_level: atom(),
          tools: list(Tools.tool_wrapper()),
          functions: list(Tools.Spec.t()),
          prompt_template: Prompts.t()
        }

  @doc """
  Creates new config with the given attributes.
  """
  def new(attrs \\ %{}) do
    config = %__MODULE__{}
    Map.merge(config, attrs)
  end
end
