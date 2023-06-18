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

  def fetch(messages, %Config{model: model, temperature: temperature, stream: true} = config) do
    body = %{
      model: model,
      temperature: temperature,
      max_tokens: Config.get_max_tokens(model),
      messages: messages
    }

    {:ok, stream} = Stream.call(body, config)
    resp = StreamReducer.reduce(stream)
    {:ok, resp}
  end

  @spec fetch(list(OpenAI.message()), list(map()), Config.t()) ::
          {:error, HTTPoison.Error.t()} | {:ok, map()}
  def fetch(messages, functions, options \\ [force: false], config)

  def fetch(
        messages,
        functions,
        options,
        %Config{
          api_url: api_url,
          retries: retries,
          stream: false
        } = config
      ) do
    url = "#{api_url}/v1/chat/completions"

    body = payload(messages, functions, options, config)

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

  def fetch(
        messages,
        functions,
        options,
        %Config{
          stream: true
        } = config
      ) do
    body = payload(messages, functions, options, config)

    {:ok, stream} = Stream.call(body, config)
    resp = StreamReducer.reduce(stream)
    {:ok, resp}
  end

  # Forces a function calling when force: true
  # Useful when querying the AI first.
  defp payload(messages, functions, [force: true], config) do
    payload = payload(messages, functions, [force: false], config)
    Map.put(payload, :function_call, %{name: List.first(functions)[:name]})
  end

  defp payload(
         messages,
         functions,
         [force: false],
         %Config{
           model: model,
           temperature: temperature,
           stream: stream
         }
       ) do
    %{
      model: model,
      stream: stream,
      temperature: temperature,
      max_tokens: Config.get_max_tokens(model),
      messages: messages,
      functions: functions
    }
  end
end
