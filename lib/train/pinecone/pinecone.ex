defmodule Train.Pinecone do
  @moduledoc """
  Basic Pinecone implementation to query & insert vectors.

  The following envs need to be declared:
    PINECONE_INDEX_NAME, PINECONE_PROJECT_NAME, PINECONE_API_ENV, PINECONE_API_KEY
  """
  require Logger

  @type embeddings :: [float()]

  alias Train.Credentials
  alias Train.Pinecone.Config

  def config(opts \\ %{}) do
    Config.new(opts)
  end

  @doc """
  Queries a namespace using a vector id or with a list of embeddings.
  """
  @spec query(String.t(), Config.t()) :: {:ok, term()} | {:error, term()}
  def query(
        vector_id,
        %Config{namespace: namespace, index: index, project: project} = config
      )
      when is_binary(vector_id) do
    body =
      Jason.encode!(%{
        "id" => vector_id,
        "topK" => config.topK || 4,
        "includeValues" => true,
        "includeMetadata" => true,
        "namespace" => namespace
      })

    url({:vectors, index, project}, "query")
    |> HTTPoison.post(body, headers())
    |> parse_response()
  end

  @spec query(embeddings(), Config.t()) :: {:ok, term()} | {:error, term()}
  def query(
        embeddings,
        %Config{namespace: namespace, index: index, project: project} = config
      ) do
    body =
      Jason.encode!(%{
        "vector" => embeddings,
        "topK" => config.topK || 4,
        "includeValues" => true,
        "includeMetadata" => true,
        "namespace" => namespace
      })

    url({:vectors, index, project}, "query")
    |> HTTPoison.post(body, headers())
    |> parse_response()
  end

  @spec query(embeddings(), map(), Config.t()) :: {:ok, term()} | {:error, term()}
  def query(
        embeddings,
        filter,
        %Config{namespace: namespace, index: index, project: project} = config
      ) do
    body =
      Jason.encode!(%{
        "vector" => embeddings,
        "filter" => filter,
        "topK" => config.topK || 4,
        "includeValues" => true,
        "includeMetadata" => true,
        "namespace" => namespace
      })

    url({:vectors, index, project}, "query")
    |> HTTPoison.post(body, headers())
    |> parse_response()
  end

  @doc """
  Deletes vectors by id, with metadata, or the entire namespace.

  ## Examples

      iex> Pinecone.delete(:all, pinecone_config)
      iex> Pinecone.delete(%{tag: "foo"}, pinecone_config)
      iex> Pinecone.delete("136a14fe-5ca3-486e-9fc8-b7b0844ec5a3"}, pinecone_config)
  """
  @spec delete(atom(), Config.t()) :: {:ok, term()} | {:error, term()}
  def delete(
        :all,
        %Config{namespace: namespace, index: index, project: project}
      ) do
    body =
      Jason.encode!(%{
        "deleteAll" => true,
        "namespace" => namespace
      })

    url({:vectors, index, project}, "vectors/delete")
    |> HTTPoison.post(body, headers())
    |> parse_response()
  end

  @spec delete(map(), Config.t()) :: {:ok, term()} | {:error, term()}
  def delete(
        filter,
        %Config{namespace: namespace, index: index, project: project}
      )
      when is_map(filter) do
    body =
      Jason.encode!(%{
        "deleteAll" => false,
        "filter" => filter,
        "namespace" => namespace
      })

    url({:vectors, index, project}, "vectors/delete")
    |> HTTPoison.post(body, headers())
    |> parse_response()
  end

  @spec delete(list(String.t()), Config.t()) :: {:ok, term()} | {:error, term()}
  def delete(
        ids,
        %Config{namespace: namespace, index: index, project: project}
      )
      when is_list(ids) do
    body =
      Jason.encode!(%{
        "deleteAll" => false,
        "ids" => ids,
        "namespace" => namespace
      })

    url({:vectors, index, project}, "vectors/delete")
    |> HTTPoison.post(body, headers())
    |> parse_response()
  end

  @doc """
  Writes vectors into a namespace.
  It overwrites previous values for an existing vector id.
  """
  @spec upsert(any(), Config.t()) :: {:ok, term()} | {:error, term()}
  def upsert(vectors, %Config{namespace: namespace, index: index, project: project}) do
    body =
      %{
        namespace: namespace,
        vectors: Enum.map(vectors, fn vector -> map_vector(vector) end)
      }
      |> Jason.encode!()

    url({:vectors, index, project}, "vectors/upsert")
    |> HTTPoison.post(body, headers())
    |> parse_response()
  end

  defp map_vector(%{content: vector, metadata: metadata}) do
    %{id: UUID.uuid4(), values: vector, metadata: metadata}
  end

  defp map_vector(%{id: _, values: _, metadata: _} = vector) do
    vector
  end

  @doc """
  List Pinecone indexes.
  """
  @spec indexes() :: {:ok, list(String.t())} | {:error, any()}
  def indexes() do
    url(:indexes, "databases")
    |> HTTPoison.get(headers())
    |> parse_response()
  end

  @doc """
  Get a description of an index.
  """
  @spec index(String.t()) :: {:ok, map()} | {:error, any()}
  def index(index_name) do
    url(:indexes, "databases/#{index_name}")
    |> HTTPoison.get(headers())
    |> parse_response()
  end

  defp parse_response(response) do
    case response do
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
    pinecone_env = Credentials.get(:pinecone, :env)
    "https://#{index}-#{project}.svc.#{pinecone_env}.pinecone.io/#{path}"
  end

  defp url(:indexes, path) do
    pinecone_env = Credentials.get(:pinecone, :env)
    "https://controller.#{pinecone_env}.pinecone.io/#{path}"
  end

  defp headers() do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      "Api-Key": Credentials.get(:pinecone, :api_key)
    ]
  end
end
