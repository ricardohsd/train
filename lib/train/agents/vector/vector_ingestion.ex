defmodule Train.Agents.VectorIngestion do
  alias Train.LlmChain
  alias Train.Pinecone
  alias Train.OpenAI
  alias Train.TextSplitter.TokenTextSplitter

  @doc """
  Ingest texto into Pinecone with the metadata.

  It may happen that the Pinecone's index has a lower dimension than
  the embeddings returned by OpenAI.
  In that case only the embedding's slice that fits Pinecone will be used during upsert.
  """
  @spec ingest(LlmChain.t(), String.t(), map(), integer()) :: {:ok, term()} | {:error, term()}
  def ingest(
        %LlmChain{openai_config: _, pinecone_config: _} = chain,
        text,
        metadata,
        chunk_size
      ) do
    {:ok, %{"database" => %{"dimension" => dimension}}} =
      Pinecone.index(chain.pinecone_config.index)

    documents =
      TokenTextSplitter.split(text, chunk_size)
      |> Enum.map(fn text ->
        {:ok, embeddings} = OpenAI.embedding(text, chain.openai_config)
        %{content: Enum.take(embeddings, dimension), metadata: parse_metadata(metadata, text)}
      end)

    documents_count = length(documents)

    {:ok, %{"upsertedCount" => ^documents_count}} =
      Pinecone.upsert(documents, chain.pinecone_config)
  end

  defp parse_metadata(metadata, text) when is_map(metadata) do
    Map.put(metadata, :text, text)
  end

  defp parse_metadata(metadata, text) do
    %{metadata: metadata, text: text}
  end
end
