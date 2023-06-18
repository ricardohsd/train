defmodule Train.OpenAI.Stream do
  require Logger

  alias Train.OpenAI.Config
  alias Train.OpenAI.Client

  @doc """
  Queries OpenAI's completions endpoint with
  a single or multiple messages and streams the response.
  """
  @spec call(String.t(), Config.t()) :: Enumerable.t()
  def call(
        body,
        %Config{
          api_url: api_url,
          stream: true
        } = config
      ) do
    url = "#{api_url}/v1/chat/completions"

    Logger.debug("-- Fetching OpenAI Stream with functions #{inspect(config)}")

    {
      :ok,
      Stream.resource(
        fn -> Client.post(url, body, config) end,
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
      |> Enum.reduce(
        {%{}, false},
        fn trimmed, {chunk, is_done?} ->
          case Jason.decode(trimmed) do
            {:ok,
             %{
               "choices" => [
                 %{"delta" => %{"role" => "assistant", "function_call" => _}}
               ]
             } = resp} ->
              {resp, false}

            {:ok, %{"choices" => [%{"delta" => %{"role" => "assistant"}}]} = resp} ->
              {resp, false}

            {:ok, %{"choices" => [%{"delta" => %{"content" => _}}]} = resp} ->
              {resp, is_done? or false}

            {:ok,
             %{
               "choices" => [
                 %{"delta" => %{"function_call" => %{"arguments" => _}}}
               ]
             } = resp} ->
              {resp, is_done? or false}

            {:ok, %{"choices" => [%{"delta" => %{}, "finish_reason" => "stop"}]} = resp} ->
              {resp, true}

            {:ok, %{"choices" => [%{"delta" => %{}, "finish_reason" => "function_call"}]} = resp} ->
              {resp, true}

            {:error, %{data: "[DONE]"}} ->
              {chunk, is_done? or true}
          end
        end
      )

    if done? do
      {[chunk], {:done, resp}}
    else
      {[chunk], resp}
    end
  end
end
