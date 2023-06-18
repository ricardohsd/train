defmodule Train.OpenAI do
  require Logger

  alias Train.OpenAI.Config
  alias Train.OpenAI.Embedding
  alias Train.OpenAI.Completions

  @type message :: %{
          required(:role) => String.t(),
          required(:content) => String.t()
        }

  @doc """
  Queries OpenAI chat completions with the given messages and return the human response.
  Accepts gpt-4 or gpt-3.5-turbo.
  """
  @spec chat(list(message()), Config.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  @spec chat(String.t(), Config.t()) ::
          {:ok, list(String.t()), String.t()} | {:error, list(String.t()), String.t()}
  def chat(messages, config) when is_list(messages) do
    with {:ok, %{"choices" => [resp | _]}} <- Completions.fetch(messages, config),
         %{"message" => %{"role" => "assistant", "content" => content}} <- resp do
      {:ok, messages, content}
    else
      {:error, %Jason.DecodeError{data: data}} -> {:error, messages, data}
      {:error, err} -> {:error, messages, err}
    end
  end

  def chat(message, config) when is_binary(message) do
    chat([%{role: "user", content: message}], config)
  end

  @doc """
  Queries OpenAI with function calling.
  """
  def chat(messages, functions, config) do
    Completions.fetch(messages, functions, config)
  end

  @doc """
  Queries OpenAI's embedding API and return the :ok and the list of embeddings.
  """
  @spec embedding(String.t(), Config.t()) :: {:ok, [float()]} | {:error, String.t()}
  def embedding(query, config) do
    with {:ok, %{"data" => [data | _]}} <- Embedding.fetch(query, config),
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
  @spec embedding!(String.t(), Config.t()) :: [float()]
  def embedding!(prompt, config) do
    case embedding(prompt, config) do
      {:ok, embeddings} -> embeddings
      {:error, error} -> raise "embedding! failed: #{inspect(error)}"
    end
  end
end
