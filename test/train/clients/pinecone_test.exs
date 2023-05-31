defmodule Train.Clients.PineconeTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Clients.OpenAIConfig
  alias Train.Clients.OpenAI
  alias Train.Clients.PineconeConfig
  alias Train.Clients.Pinecone

  @prompt "o que é o divorcio?"

  setup_all do
    HTTPoison.start()
    %{config: OpenAIConfig.new(%{model: :"gpt-3.5-turbo"})}
  end

  test "fetching vectors for a given embedding", %{config: config} do
    {:ok, embeddings} =
      use_cassette "open_ai/divorce" do
        OpenAI.embedding(@prompt, config)
      end

    use_cassette "pinecone/embedding" do
      {:ok, %{"matches" => matches}} =
        Pinecone.query(embeddings, %PineconeConfig{namespace: nil, topK: 2})

      assert length(matches) == 2

      [doc | _tail] = matches

      %{"metadata" => %{"metadata" => _, "text" => text}} = doc

      assert String.contains?(
               text,
               "Art. 1.576. A separação judicial põe termo aos deveres de coabitação e fidelidade recíproca"
             )
    end
  end

  test "with nil embeddings" do
    use_cassette "pinecone/nil" do
      {:error, %HTTPoison.Response{status_code: 400}} =
        Pinecone.query(nil, %PineconeConfig{namespace: nil})
    end
  end
end
