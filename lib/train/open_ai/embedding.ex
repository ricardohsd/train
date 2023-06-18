defmodule Train.OpenAI.Embedding do
  require Logger

  alias Train.OpenAI.Config
  alias Train.OpenAI.Client

  @spec fetch(String.t(), Config.t()) :: {:ok, map()} | {:error, any()}
  def fetch(prompt, %Config{api_url: api_url} = config) do
    url = "#{api_url}/v1/embeddings"

    body = %{
      model: "text-embedding-ada-002",
      input: prompt
    }

    Logger.debug("-- Fetching OpenAI embeddings, Config: #{inspect(config)}")

    Client.post(url, body, [], %{config | stream: false})
  end
end
