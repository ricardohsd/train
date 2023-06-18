defmodule Train.Pinecone.Config do
  alias Train.Credentials

  defstruct namespace: nil, index: nil, project: nil, topK: 1

  @type t :: %{
          required(:namespace) => String.t(),
          required(:index) => String.t(),
          required(:project) => String.t(),
          optional(:topK) => integer()
        }

  def new(opts \\ %{}) do
    config = %__MODULE__{
      index: Credentials.get(:pinecone, :index),
      project: Credentials.get(:pinecone, :project)
    }

    Map.merge(config, opts)
  end
end
