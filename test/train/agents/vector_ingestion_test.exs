defmodule Train.Clients.VectorIngestionTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Train.Clients.PineconeConfig
  alias Train.OpenAI
  alias Train.Agents.VectorIngestion

  setup_all do
    HTTPoison.start()

    chain =
      Train.LlmChain.new(%{
        memory: nil,
        tools: [],
        openai_config: OpenAI.Config.new(%{model: :"gpt-3.5-turbo"}),
        pinecone_config:
          PineconeConfig.new(%{namespace: "food", topK: 5, index: "localtest", project: "1234567"})
      })

    %{chain: chain}
  end

  test "insert text", %{chain: chain} do
    use_cassette "agents/vector_ingestion" do
      text =
        "Cascão da Silva Pereira Alves (born January 14, 1969) is an Brazilian musician. He is the founder of the rock band Casca Dura, for which he is the lead singer, guitarist, and principal songwriter. Prior to forming Casca Dura, he was the drummer of rock band Solitarios from 1990 to 1994."

      chunk_size = 30

      resp =
        VectorIngestion.ingest(
          chain,
          text,
          %{album: "The great life of Pereira Alves"},
          chunk_size
        )

      assert {:ok, %{"upsertedCount" => 3}} == resp
    end
  end
end
