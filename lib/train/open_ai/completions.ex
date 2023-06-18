defmodule Train.OpenAI.Completions do
  require Logger

  alias Train.OpenAI.Config
  alias Train.OpenAI.Client
  alias Train.OpenAI.Stream
  alias Train.OpenAI
  alias Train.OpenAI.StreamReducer

  @doc """
  Queries OpenAI chat completions with the given messages and returns the API's response.
  Accepts gpt-4 or gpt-3.5-turbo.
  """
  @spec fetch(list(OpenAI.message()), Config.t()) :: {:error, HTTPoison.Error.t()} | {:ok, map()}
  def fetch(_, %Config{retries: 0}) do
    {:error, %HTTPoison.Error{reason: "timeout", id: nil}}
  end

  def fetch(messages, %Config{api_url: api_url, stream: false, retries: retries} = config) do
    url = "#{api_url}/v1/chat/completions"

    %{model: model, temperature: temperature} = config

    body = %{
      model: model,
      temperature: temperature,
      max_tokens: Config.get_max_tokens(model),
      messages: messages
    }

    options = [recv_timeout: config.recv_timeout, timeout: config.timeout]

    Logger.debug("-- Fetching OpenAI chat, Config: #{inspect(config)}")

    case Client.post(url, body, options, config) do
      {:error, %HTTPoison.Error{reason: :timeout}} ->
        Logger.debug("-- Retrying #{retries}, Config: #{inspect(config)}")
        Process.sleep(config.retry_backoff)
        fetch(messages, %Config{config | retries: retries - 1})

      {:ok, body} ->
        {:ok, body}

      other ->
        other
    end
  end

  def fetch(messages, %Config{stream: true} = config) do
    {:ok, _, stream} = Stream.call(messages, config)
    resp = StreamReducer.reduce(stream)
    {:ok, resp}
  end

  @spec fetch(list(OpenAI.message()), list(map()), Config.t()) ::
          {:error, HTTPoison.Error.t()} | {:ok, map()}
  def fetch(
        messages,
        functions,
        %Config{api_url: api_url, stream: false, retries: retries} = config
      ) do
    url = "#{api_url}/v1/chat/completions"

    %{model: model, temperature: temperature} = config

    body = %{
      model: model,
      temperature: temperature,
      max_tokens: Config.get_max_tokens(model),
      messages: messages,
      functions: functions
    }

    options = [recv_timeout: config.recv_timeout, timeout: config.timeout]

    Logger.debug("-- Fetching OpenAI chat, Config: #{inspect(config)}")

    case Client.post(url, body, options, config) do
      {:error, %HTTPoison.Error{reason: :timeout}} ->
        Logger.debug("-- Retrying #{retries}, Config: #{inspect(config)}")
        Process.sleep(config.retry_backoff)
        fetch(messages, functions, %Config{config | retries: retries - 1})

      {:ok, body} ->
        {:ok, body}

      other ->
        other
    end
  end

  def fetch(messages, functions, %Config{stream: true} = config) do
    {:ok, _, stream} = Stream.call(messages, functions, config)
    resp = StreamReducer.reduce(stream)
    {:ok, resp}
  end
end
