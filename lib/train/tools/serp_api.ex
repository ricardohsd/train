defmodule Train.Tools.SerpApi do
  @behaviour Train.Tools.Spec

  require Logger

  @impl true
  @spec query(String.t(), number) :: {:error, any} | {:ok, String.t()}
  def query(query, retry \\ 5) do
    with {:ok, data} <- call(query, retry) do
      parse(data)
    else
      {:error, %Jason.DecodeError{}} ->
        {:error, "invalid json"}

      {:error, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "http error #{status_code}"}

      err ->
        err
    end
  end

  defp parse(%{"answer_box" => %{"answer" => answer}}) do
    {:ok, answer}
  end

  defp parse(%{
         "answer_box" => %{
           "type" => "population_result",
           "population" => population,
           "year" => year
         }
       }) do
    {:ok, "#{population}, #{year}"}
  end

  defp parse(%{"answer_box" => %{"snippet" => snippet, "list" => list}}) do
    answer = snippet <> ": " <> Enum.join(list, "; ")
    {:ok, answer}
  end

  defp parse(%{"answer_box" => %{"snippet_highlighted_words" => [head | _]}}) do
    {:ok, head}
  end

  defp parse(%{"sports_results" => %{"game_spotlight" => game_spotlight}}) do
    game_spotlight = Map.delete(game_spotlight, "video_highlights")

    teams =
      game_spotlight["teams"]
      |> Enum.map(fn t ->
        Map.delete(t, "thumbnail")
      end)

    game_spotlight = %{game_spotlight | "teams" => teams}
    Jason.encode(game_spotlight)
  end

  defp parse(%{"knowledge_graph" => %{"description" => description}}) do
    {:ok, description}
  end

  defp parse(%{"organic_results" => [%{"snippet" => snippet} | _]}) do
    {:ok, snippet}
  end

  defp parse(_) do
    {:ok, "No good search result found"}
  end

  # Return timeout error when retry count reaches 0
  defp call(_, 0) do
    {:error, %HTTPoison.Error{reason: :timeout, id: nil}}
  end

  defp call(query, retry) do
    url = "https://serpapi.com/search.json"

    params = %{
      "api_key" => System.get_env("SERPAPI_API_KEY"),
      "engine" => "google",
      "google_domain" => "google.com",
      "q" => query
    }

    case HTTPoison.get(url, %{}, params: params) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}}
      when is_integer(code) and code >= 200 and code < 300 ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: code} = resp}
      when is_integer(code) and code >= 300 ->
        {:error, resp}

      {:error, %HTTPoison.Error{reason: :timeout}} ->
        Logger.debug("----Retrying SerpApi #{retry}")
        call(query, retry - 1)

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
