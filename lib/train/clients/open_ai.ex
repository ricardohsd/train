defmodule Train.Clients.OpenAI do
  require Logger

  alias Train.Clients.OpenAIConfig

  @type message :: %{
          required(:role) => String.t(),
          required(:content) => String.t()
        }

  @doc """
  Queries OpenAI chat completions with the given messages.
  Accepts gpt-4 or gpt-3.5-turbo.
  """
  @spec generate(:user, String.t(), OpenAIConfig.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def generate(:user, message, config) do
    generate(:messages, [%{role: "user", content: message}], config)
  end

  @spec generate(:messages, list(message()), OpenAIConfig.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def generate(:messages, messages, config) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           chat(messages, config),
         {:ok, %{"choices" => [resp | _]}} <- Jason.decode(body),
         %{"message" => %{"role" => "assistant", "content" => content}} <- resp do
      {:ok, messages, content}
    else
      err ->
        err
    end
  end

  # Return timeout error when retry count reaches 0
  defp chat(_, %OpenAIConfig{retries: 0}) do
    {:error, %HTTPoison.Error{reason: :timeout, id: nil}}
  end

  defp chat(messages, %OpenAIConfig{api_url: api_url, retries: retries} = config) do
    url = "#{api_url}/v1/chat/completions"

    %{model: model, temperature: temperature} = config

    body =
      Jason.encode!(%{
        model: model,
        temperature: temperature,
        max_tokens: OpenAIConfig.get_max_tokens(model),
        messages: messages
      })

    {:ok, tokens} = ExTiktoken.CL100K.encode(body)
    log("-- Tokens: #{length(tokens)}", config)

    options = [recv_timeout: config.recv_timeout, timeout: config.timeout]

    log("-- Fetching OpenAI chat", config)

    case HTTPoison.post(url, body, headers(), options) do
      {:error, %HTTPoison.Error{reason: :timeout}} ->
        log("-- Retrying #{retries}", config)
        Process.sleep(config.retry_backoff)
        chat(messages, %OpenAIConfig{config | retries: retries - 1})

      other ->
        other
    end
  end

  @doc """
  Accepts a prompt string and queries OpenAI's embedding API and return the list of embeddings/
  """
  @spec embedding(String.t(), OpenAIConfig.t()) :: {:ok, [float()]} | {:error, String.t()}
  def embedding(prompt, %OpenAIConfig{api_url: api_url}) do
    with {:ok, %{"data" => [data | _]}} <- _embedding(prompt, api_url),
         %{"embedding" => embeddings} <- data do
      {:ok, embeddings}
    else
      {:error, %Jason.DecodeError{}} ->
        {:error, "invalid json"}

      {:error, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "http error #{status_code}"}

      {:error, message} ->
        {:error, message}
    end
  end

  defp _embedding(prompt, api_url) do
    url = "#{api_url}/v1/embeddings"

    body =
      Jason.encode!(%{
        model: "text-embedding-ada-002",
        input: prompt
      })

    case HTTPoison.post(url, body, headers()) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}}
      when is_integer(code) and code >= 200 and code < 300 ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: code} = resp}
      when is_integer(code) and code >= 300 ->
        {:error, resp}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warning("Embedding call errored with: #{reason}")
        {:error, reason}
    end
  end

  defp headers() do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: "Bearer #{System.get_env("OPENAI_API_KEY")}"
    ]
  end

  defp log(message, %OpenAIConfig{log_level: log_level}) do
    Logger.log(log_level, message)
  end
end
