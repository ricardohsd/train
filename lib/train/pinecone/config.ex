defmodule Train.Pinecone.Config do
  defstruct namespace: nil, index: nil, project: nil, topK: 1

  @type t :: %{
          required(:namespace) => String.t(),
          required(:index) => String.t(),
          required(:project) => String.t(),
          optional(:topK) => integer()
        }

  def new(opts \\ %{}) do
    config = %__MODULE__{
      index: System.get_env("PINECONE_INDEX_NAME"),
      project: System.get_env("PINECONE_PROJECT_NAME")
    }

    Map.merge(config, opts)
  end
end
