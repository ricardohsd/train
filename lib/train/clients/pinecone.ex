defmodule Train.Clients.Pinecone do
  @moduledoc """
  Basic Pinecone implementation to query & insert vectors.

  The following envs need to be declared:
    PINECONE_INDEX_NAME, PINECONE_API_ENV, PINECONE_API_KEY
  """
  require Logger

  @type params :: %{
          required(:vector) => [float()],
          required(:namespace) => String.t(),
          optional(:topK) => integer()
        }

  @doc """
  Vectory similarity query.
  """
  @spec query(params()) :: {:ok, term()} | {:error, term()}
  def query(%{vector: vector, namespace: namespace} = params) do
    body =
      Jason.encode!(%{
        "vector" => vector,
        "topK" => params[:topK] || 4,
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
