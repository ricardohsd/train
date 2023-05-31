defmodule Train.Clients.Pinecone do
  @moduledoc """
  Basic Pinecone implementation to query & insert vectors.

  The following envs need to be declared:
    PINECONE_INDEX_NAME, PINECONE_PROJECT_NAME, PINECONE_API_ENV, PINECONE_API_KEY
  """
  require Logger

  @type embeddings :: [float()]

  alias Train.Clients.PineconeConfig

  @doc """
  Vectory similarity query.
  """
  @spec query(embeddings(), PineconeConfig.t()) :: {:ok, term()} | {:error, term()}
  def query(
        embeddings,
        %PineconeConfig{namespace: namespace, index: index, project: project} = config
      ) do
    body =
      Jason.encode!(%{
        "vector" => embeddings,
        "topK" => config.topK || 4,
        "includeValues" => true,
        "includeMetadata" => true,
        "namespace" => namespace
      })

    post({:vectors, index, project}, "query", body, headers())
  end

  @spec upsert(any(), PineconeConfig.t()) :: {:ok, term()} | {:error, term()}
  def upsert(vectors, %PineconeConfig{namespace: namespace, index: index, project: project}) do
    body =
      %{
        namespace: namespace,
        vectors:
          Enum.map(vectors, fn %{content: vector, metadata: metadata} ->
            %{id: UUID.uuid4(), values: vector, metadata: metadata}
          end)
      }
      |> Jason.encode!()

    with {:ok, %{"upsertedCount" => upsertedCount} = resp} <-
           post({:vectors, index, project}, "vectors/upsert", body, headers()) do
      if is_nil(upsertedCount) do
        {:error, resp}
      else
        {:ok, upsertedCount}
      end
    else
      err -> err
    end
  end

  @spec indexes() :: {:ok, list(String.t())} | {:error, any()}
  def indexes() do
    get(:indexes, "databases", headers())
  end

  @spec index(String.t()) :: {:ok, map()} | {:error, any()}
  def index(index_name) do
    get(:indexes, "databases/#{index_name}", headers())
  end

  defp get(type, path, headers) do
    case HTTPoison.get(url(type, path), headers) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}}
      when is_integer(code) and code >= 200 and code < 300 ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: code} = resp}
      when is_integer(code) and code >= 300 ->
        {:error, resp}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Pinecone call errored with #{reason}")
        {:error, reason}
    end
  end

  defp post(type, path, body, headers) do
    case HTTPoison.post(url(type, path), body, headers) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}}
      when is_integer(code) and code >= 200 and code < 300 ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: code} = resp}
      when is_integer(code) and code >= 300 ->
        {:error, resp}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Pinecone call errored with #{reason}")
        {:error, reason}
    end
  end

  defp url({:vectors, index, project}, path) do
    pinecone_env = System.get_env("PINECONE_API_ENV")
    "https://#{index}-#{project}.svc.#{pinecone_env}.pinecone.io/#{path}"
  end

  defp url(:indexes, path) do
    pinecone_env = System.get_env("PINECONE_API_ENV")
    "https://controller.#{pinecone_env}.pinecone.io/#{path}"
  end

  defp headers() do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      "Api-Key": System.get_env("PINECONE_API_KEY")
    ]
  end
end
