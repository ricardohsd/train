defmodule Train.Credentials do
  @moduledoc """
  Get credentials from Livebook env vars if present, or the application's config.
  """

  def get(scope, key) do
    from_livebook(scope)[key] || from_app(scope)[key]
  end

  defp from_app(scope) do
    Application.get_env(:train, scope)
  end

  defp from_livebook(scope) do
    creds = %{
      pinecone: %{
        api_key: System.get_env("LB_PINECONE_API_KEY"),
        env: System.get_env("LB_PINECONE_API_ENV"),
        index: System.get_env("LB_PINECONE_INDEX_NAME"),
        project: System.get_env("LB_PINECONE_PROJECT_NAME")
      },
      serpapi: %{
        api_key: System.get_env("LB_SERPAPI_API_KEY")
      },
      open_ai: %{
        api_key: System.get_env("LB_OPENAI_API_KEY")
      }
    }

    creds[scope]
  end
end
