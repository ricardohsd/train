defmodule Train.OpenAI.Client do
  require Logger

  alias Train.Credentials
  alias Train.OpenAI.Config
  alias Train.Tiktoken

  def post(url, body, options \\ [], config)

  def post(url, body, options, %Config{stream: true} = config) do
    json = Jason.encode!(body)

    tokens = Tiktoken.count_tokens(json)
    Logger.debug("-- Stream, Tokens: #{tokens}, Config: #{inspect(config)}")

    HTTPoison.post!(
      url,
      json,
      headers(),
      Keyword.merge(options, stream_to: self(), async: :once)
    )
  end

  def post(url, body, options, %Config{stream: false} = config) do
    json = Jason.encode!(body)

    tokens = Tiktoken.count_tokens(json)
    Logger.debug("-- Tokens: #{tokens}, Config: #{inspect(config)}")

    case HTTPoison.post(url, json, headers(), options) do
      {:error, %HTTPoison.Error{reason: :timeout} = err} ->
        {:error, err}

      {:ok, %HTTPoison.Response{status_code: code, body: body}}
      when is_integer(code) and code >= 200 and code < 300 ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: code} = resp}
      when is_integer(code) and code >= 300 ->
        {:error, resp}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp headers() do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: "Bearer #{Credentials.get(:open_ai, :api_key)}"
    ]
  end
end
