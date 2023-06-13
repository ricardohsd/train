defmodule Train.Clients.OpenAIConfig do
  defstruct api_url: nil,
            model: nil,
            retries: 5,
            temperature: 0.5,
            log_level: :debug,
            retry_backoff: 10000,
            recv_timeout: 20000,
            timeout: 20000,
            stream: false

  @type t :: %__MODULE__{
          api_url: String.t(),
          model: String.t(),
          retries: integer(),
          temperature: float(),
          log_level: atom(),
          retry_backoff: integer(),
          recv_timeout: integer(),
          timeout: integer(),
          stream: boolean()
        }

  @type model :: :"gpt-4" | :"gpt-3.5-turbo" | :"gpt-3.5-turbo-16k"

  @api_url "https://api.openai.com"
  @max_tokens %{:"gpt-3.5-turbo" => 2048, :"gpt-4" => 4096, :"gpt-3.5-turbo-16k" => 8192}

  def new(opts \\ %{}) do
    config = %__MODULE__{api_url: @api_url, model: :"gpt-4"}
    Map.merge(config, opts)
  end

  @spec get_max_tokens(model()) :: integer()
  def get_max_tokens(model) do
    @max_tokens[model]
  end

  @spec api_url() :: String.t()
  def api_url() do
    @api_url
  end
end
