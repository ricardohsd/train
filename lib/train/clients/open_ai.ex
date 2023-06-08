defmodule Train.Clients.OpenAI do
  require Logger

  alias Train.Clients.OpenAIConfig

  @type message :: %{
          required(:role) => String.t(),
          required(:content) => String.t()
        }

  @spec generate(:user, String.t(), OpenAIConfig.t()) ::
          {:error, [binary], binary} | {:ok, any, binary}
  @spec generate(:messages, list(message()), OpenAIConfig.t()) ::
          {:error, [binary], binary} | {:ok, any, binary}
  def generate(:user, message, config) do
    generate(:messages, [%{role: "user", content: message}], config)
  end

  def generate(:messages, messages, %OpenAIConfig{stream: false} = config) do
    completions(:messages, messages, config)
  end

  def generate(:messages, messages, %OpenAIConfig{stream: true} = config) do
    {:ok, messages, stream} = stream(:messages, messages, config)

    {:ok, messages, stream |> Enum.join("")}
  end

  @doc """
  Queries OpenAI chat completions with the given messages.
  Accepts gpt-4 or gpt-3.5-turbo.
  """
  @spec completions(:user, String.t(), OpenAIConfig.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def completions(:user, message, config) do
    completions(:messages, [%{role: "user", content: message}], config)
  end

  @spec completions(:messages, list(message()), OpenAIConfig.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def completions(:messages, messages, config) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           chat(messages, config),
         {:ok, %{"choices" => [resp | _]}} <- Jason.decode(body),
         %{"message" => %{"role" => "assistant", "content" => content}} <- resp do
      {:ok, messages, content}
    else
      {:error, %Jason.DecodeError{data: data}} -> {:error, messages, data}
      {:error, %HTTPoison.Error{reason: "timeout", id: nil}} -> {:error, messages, "timeout"}
    end
  end

  # Return timeout error when retry count reaches 0
  defp chat(_, %OpenAIConfig{retries: 0}) do
    {:error, %HTTPoison.Error{reason: "timeout", id: nil}}
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
  Queries OpenAI's embedding API and return the :ok and the list of embeddings.
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

  @doc """
  Similar to embedding/2 but raises if there is a problem fetching the embeddings.
  """
  @spec embedding!(String.t(), OpenAIConfig.t()) :: [float()]
  def embedding!(prompt, config) do
    case embedding(prompt, config) do
      {:ok, embeddings} -> embeddings
      {:error, error} -> raise "embedding! failed: #{inspect(error)}"
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

  @doc """
  Queries OpenAI's completions endpoint with
  a single or multiple messages and streams the response.
  """
  @spec stream(:messages, list(message()), OpenAIConfig.t()) :: Enumerable.t()
  def stream(
        :messages,
        messages,
        %OpenAIConfig{
          api_url: api_url,
          model: model,
          temperature: temperature
        } = config
      ) do
    url = "#{api_url}/v1/chat/completions"

    body =
      Jason.encode!(%{
        model: model,
        stream: true,
        temperature: temperature,
        max_tokens: OpenAIConfig.get_max_tokens(model),
        messages: messages
      })

    log("-- Fetching OpenAI Stream", config)

    {
      :ok,
      messages,
      Stream.resource(
        fn -> HTTPoison.post!(url, body, headers(), stream_to: self(), async: :once) end,
        &handle_async_response/1,
        &close_async_response/1
      )
    }
  end

  defp close_async_response(resp) do
    :hackney.stop_async(resp)
  end

  defp handle_async_response({:done, resp}) do
    {:halt, resp}
  end

  defp handle_async_response(%HTTPoison.AsyncResponse{id: id} = resp) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: code} ->
        Logger.debug("openai,request,status,#{inspect(code)}")
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncHeaders{id: ^id, headers: headers} ->
        Logger.debug("openai,request,headers,#{inspect(headers)}")
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        HTTPoison.stream_next(resp)
        parse_chunk(chunk, resp)

      %HTTPoison.AsyncEnd{id: ^id} ->
        {:halt, resp}
    end
  end

  defp parse_chunk(chunk, resp) do
    {chunk, done?} =
      chunk
      |> String.split("data:")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce({"", false}, fn trimmed, {chunk, is_done?} ->
        case Jason.decode(trimmed) do
          {:ok, %{"choices" => [%{"delta" => %{"role" => "assistant"}}]}} ->
            {chunk, false}

          {:ok, %{"choices" => [%{"delta" => %{"content" => text}}]}} ->
            {chunk <> text, is_done? or false}

          {:ok, %{"choices" => [%{"delta" => %{}, "finish_reason" => "stop"}]}} ->
            {chunk, true}

          {:error, %{data: "[DONE]"}} ->
            {chunk, is_done? or true}
        end
      end)

    if done? do
      {[chunk], {:done, resp}}
    else
      {[chunk], resp}
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
