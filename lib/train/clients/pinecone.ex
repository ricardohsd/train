defmodule Train.Clients.Pinecone do
  @moduledoc """
  Basic Pinecone implementation to query & insert vectors.

  The following envs need to be declared:
    PINECONE_INDEX_NAME, PINECONE_API_ENV, PINECONE_API_KEY
  """
  require Logger

  @type embeddings :: [float()]

  defmodule Config do
    defstruct namespace: nil, topK: 1

    @type t :: %{
            required(:namespace) => String.t(),
            optional(:topK) => integer()
          }
  end

  @doc """
  Vectory similarity query.
  """
  @spec query(embeddings, Config.t()) :: {:ok, term()} | {:error, term()}
  def query(embeddings, %{namespace: namespace} = config) do
    body =
      Jason.encode!(%{
        "vector" => embeddings,
        "topK" => config.topK || 4,
        "includeValues" => true,
        "includeMetadata" => true,
        "namespace" => namespace
      })

    case HTTPoison.post(url(), body, headers()) do
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

  defp url() do
    pinecone_index = System.get_env("PINECONE_INDEX_NAME")
    pinecone_env = System.get_env("PINECONE_API_ENV")
    "https://#{pinecone_index}.svc.#{pinecone_env}.pinecone.io/query"
  end

  defp headers() do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      "Api-Key": System.get_env("PINECONE_API_KEY")
    ]
  end
end
